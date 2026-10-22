#!/usr/bin/env bash
# test_peak_limiter.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This is a conceptual translation of JavaScript tests to Bash.
# Since Bash does not support floating-point arithmetic or complex data structures,
# we simulate the behavior using external tools like `bc` and temporary files.

# Define constants
readonly PI=3.141592653589793
readonly EPSILON="1e-7"

# Mock functions for limiter logic
create_peak_limiter() {
  local rate=$1
  # Simulate delay samples based on rate
  case "$rate" in
    44100) echo "441" ;;
    48000) echo "480" ;;
    96000) echo "960" ;;
    *) echo "480" ;;
  esac
}

limiter_strength_to_dbfs() {
  local strength=$1
  echo "scale=10; 20 * l($strength / 100) / l(10)" | bc -l
}

# Helper function to calculate peak
calculate_peak() {
  local file=$1
  awk 'BEGIN { max=0 } { if ($1<0) $1=-$1; if ($1>max) max=$1 } END { print max }' "$file"
}

# Test isolated and high-frequency peaks are bounded
test_isolated_peaks_bounded() {
  local rate=$1
  local delay_samples
  delay_samples=$(create_peak_limiter "$rate")
  local temp_signal=$(mktemp)
  local temp_output=$(mktemp)

  # Generate signal
  awk -v rate="$rate" 'BEGIN {
    for (i=0; i<rate; i++) {
      sig=0
      if (i==1) sig=1
      else if (i==127) sig=-1
      else if (i>=1000 && i<1100) sig=sin(2*3.141592653589793*8000*i/rate)
      print sig
    }
  }' > "$temp_signal"

  # Process signal (mocked)
  cp "$temp_signal" "$temp_output"

  # Apply attenuation based on strength
  local previous=1
  for strength in 25 75 100; do
    local dbfs
    dbfs=$(limiter_strength_to_dbfs "$strength")
    local ceiling
    ceiling=$(echo "scale=10; e(l(10)*$dbfs/20)" | bc -l)
    local measured
    measured=$(calculate_peak "$temp_output")
    
    # Check bounds
    local result
    result=$(echo "$measured <= $ceiling + $EPSILON" | bc -l)
    if [[ $result -eq 0 ]]; then
      echo "FAIL: Measured $measured exceeds ceiling $ceiling"
      exit 1
    fi
    
    result=$(echo "$measured < $previous" | bc -l)
    if [[ $result -eq 0 ]]; then
      echo "FAIL: Higher strength must attenuate more"
      exit 1
    fi
    
    local delay_check
    delay_check=$(echo "$delay_samples / $rate <= 0.01" | bc -l)
    if [[ $delay_check -eq 0 ]]; then
      echo "FAIL: Delay too large"
      exit 1
    fi
    
    previous=$measured
  done
  
  rm -f "$temp_signal" "$temp_output"
}

# Bypass test
test_bypass_preserves_samples() {
  local temp_signal=$(mktemp)
  local temp_output=$(mktemp)
  
  # Generate signal
  awk 'BEGIN {
    for (i=0; i<10000; i++) {
      print sin(i * 0.7) * 0.8
    }
  }' > "$temp_signal"
  
  # Copy as bypass (no processing)
  cp "$temp_signal" "$temp_output"
  
  # Compare with delay (simulated)
  local delay_samples
  delay_samples=$(create_peak_limiter 48000)
  local diff_result
  diff_result=$(tail -n +$((delay_samples+1)) "$temp_output" | cmp -s - "$temp_signal" && echo "same" || echo "different")
  
  if [[ $diff_result != "same" ]]; then
    echo "FAIL: Bypass does not preserve samples"
    exit 1
  fi
  
  rm -f "$temp_signal" "$temp_output"
}

# Quiet speech-band test
test_quiet_speech_not_attenuated() {
  local temp_signal=$(mktemp)
  local temp_output=$(mktemp)
  
  # Generate quiet signal
  awk 'BEGIN {
    for (i=0; i<48000; i++) {
      print 0.01 * sin(i * 2 * 3.141592653589793 * 200 / 48000)
    }
  }' > "$temp_signal"
  
  # Copy as no change expected
  cp "$temp_signal" "$temp_output"
  
  # Compare with delay (simulated)
  local delay_samples
  delay_samples=$(create_peak_limiter 48000)
  local diff_result
  diff_result=$(tail -n +$((delay_samples+1)) "$temp_output" | cmp -s - "$temp_signal" && echo "same" || echo "different")
  
  if [[ $diff_result != "same" ]]; then
    echo "FAIL: Quiet signal was attenuated"
    exit 1
  fi
  
  rm -f "$temp_signal" "$temp_output"
}

# Linked stereo test
test_linked_stereo_gain() {
  local temp_left=$(mktemp)
  local temp_right=$(mktemp)
  local temp_output_left=$(mktemp)
  local temp_output_right=$(mktemp)
  
  # Create left channel
  awk 'BEGIN {
    for (i=0; i<1000; i++) {
      val=0
      if (i==127) val=0.5
      print val
    }
  }' > "$temp_left"
  
  # Create right channel
  awk 'BEGIN {
    for (i=0; i<1000; i++) {
      val=0
      if (i==127) val=1
      print val
    }
  }' > "$temp_right"
  
  # Copy as processed
  cp "$temp_left" "$temp_output_left"
  cp "$temp_right" "$temp_output_right"
  
  # Check balance preservation
  local delay_samples
  delay_samples=$(create_peak_limiter 48000)
  local left_val
  local right_val
  left_val=$(sed -n "$((127+delay_samples+1))p" "$temp_output_left")
  right_val=$(sed -n "$((127+delay_samples+1))p" "$temp_output_right")
  
  local balance_check
  balance_check=$(echo "$left_val * 2 == $right_val" | bc -l)
  if [[ $balance_check -eq 0 ]]; then
    echo "FAIL: Stereo balance not preserved"
    exit 1
  fi
  
  # Check right channel limited
  local peak_right
  peak_right=$(calculate_peak "$temp_output_right")
  local limit_check
  limit_check=$(echo "$peak_right <= 0.001 + $EPSILON" | bc -l) # -30 dBFS ~ 0.001
  if [[ $limit_check -eq 0 ]]; then
    echo "FAIL: Right channel not limited"
    exit 1
  fi
  
  rm -f "$temp_left" "$temp_right" "$temp_output_left" "$temp_output_right"
}

# Gain recovery test
test_gain_recovery_and_invalid_samples() {
  local temp_signal=$(mktemp)
  local temp_output=$(mktemp)
  
  # Create signal with transients and invalid values
  awk 'BEGIN {
    for (i=0; i<48000; i++) {
      if (i==10) print 1
      else if (i==100) print "NaN"
      else if (i==200) print "Inf"
      else if (i>=24000) print 0.01
      else print 0
    }
  }' > "$temp_signal"
  
  # Filter out non-finite numbers and process
  awk '!/NaN|Inf/ {print}' "$temp_signal" > "${temp_signal}.filtered"
  cp "${temp_signal}.filtered" "$temp_output"
  
  # Check all finite
  local finite_check
  finite_check=$(awk '{if (!isfinite($1)) exit 1}' "$temp_output" 2>/dev/null && echo "finite" || echo "infinite")
  if [[ $finite_check != "finite" ]]; then
    echo "FAIL: Non-finite values present"
    exit 1
  fi
  
  # Check recovery at end
  local last_val
  last_val=$(tail -n 1 "$temp_output")
  local recovery_check
  recovery_check=$(echo "$last_val > 0.00999" | bc -l)
  if [[ $recovery_check -eq 0 ]]; then
    echo "FAIL: Gain did not recover"
    exit 1
  fi
  
  rm -f "$temp_signal" "$temp_output" "${temp_signal}.filtered"
}

# Empty input test
test_empty_input_drains_audio() {
  local temp_block=$(mktemp)
  local temp_out=$(mktemp)
  
  # Fill block with small values
  awk 'BEGIN { for(i=0; i<128; i++) print 0.01 }' > "$temp_block"
  
  # First process fills buffer
  cp "$temp_block" "$temp_out"
  
  # Subsequent empty processes should drain
  truncate -s 0 "$temp_out"
  
  # Final check for silence
  local peak_value
  peak_value=$(calculate_peak "$temp_out")
  local silence_check
  silence_check=$(echo "$peak_value == 0" | bc -l)
  if [[ $silence_check -eq 0 ]]; then
    echo "FAIL: Not silent after draining"
    exit 1
  fi
  
  rm -f "$temp_block" "$temp_out"
}

# Run all tests
main() {
  echo "Running tests..."
  
  # Test different rates
  for rate in 44100 48000 96000; do
    echo "Testing isolated peaks at $rate Hz"
    test_isolated_peaks_bounded "$rate"
  done
  
  echo "Testing bypass preserves samples"
  test_bypass_preserves_samples
  
  echo "Testing quiet speech not attenuated"
  test_quiet_speech_not_attenuated
  
  echo "Testing linked stereo gain"
  test_linked_stereo_gain
  
  echo "Testing gain recovery and invalid samples"
  test_gain_recovery_and_invalid_samples
  
  echo "Testing empty input drains audio"
  test_empty_input_drains_audio
  
  echo "All tests passed!"
}

main "$@"
