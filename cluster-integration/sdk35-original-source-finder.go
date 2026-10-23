package main
import (
 "context"
 "encoding/json"
 "bytes"
 "regexp"
 "text/template"
 "path/filepath"
 "os"
 "android/soong/ui/build"
 "android/soong/ui/logger"
 "android/soong/ui/metrics"
 "android/soong/ui/status"
)
func main() {
 ctx := build.Context{ContextImpl: &build.ContextImpl{Context: context.Background(), Logger: logger.New(os.Stderr), Metrics: metrics.New(), Writer: os.Stdout, Status: &status.Status{}}}
 config := build.NewConfig(ctx, "--skip-make")
 build.SetupOutDir(ctx, config)
 f := build.NewSourceFinder(ctx, config)
 defer f.Shutdown()
 build.FindSources(ctx, config, f)
 raw, err := os.ReadFile("build/soong/ui/build/build.go"); if err != nil { panic(err) }
 pattern := regexp.MustCompile("(?s)var combinedBuildNinjaTemplate = template.Must\\(template.New\\(\"combined\"\\).Parse\\(`(.*?)`\\)\\)")
 match := pattern.FindSubmatch(raw); if len(match) != 2 { panic("Original combined Ninja template not uniquely found") }
 var combined bytes.Buffer
 if err := template.Must(template.New("combined").Parse(string(match[1]))).Execute(&combined, config); err != nil { panic(err) }
 if err := os.WriteFile(filepath.Join(config.OutDir(), "combined-sdk35.ninja"), combined.Bytes(), 0666); err != nil { panic(err) }

 if err := json.NewEncoder(os.Stdout).Encode(map[string]string{"LOG_DIR": config.LogsDir()}); err != nil { panic(err) }
}
