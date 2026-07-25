(function () {
  "use strict";

  const nativeSetTimeout = window.setTimeout.bind(window);
  const nativeSetInterval = window.setInterval.bind(window);
  const interruptionTimer = /(loginmodal|login_modal|loginprompt|login_prompt|signinmodal|sign_in_modal|signinprompt|sign_in_prompt|authmodal|auth_modal|unauth|guestmode|guest_mode|watchlimit|watch_limit|browselimit|browse_limit|continuewatching|continue_watching|keepwatching|keep_watching|watchtime|watch_time|openappmodal|open_app_modal|appprompt|app_prompt|interruption|timedpopup|timed_popup)/i;

  function isLivePage() {
    return /^\/@[^/]+\/live\/?$/i.test(location.pathname) || /^\/embed\/live\/@?[^/?#]+\/?$/i.test(location.pathname);
  }

  function blocksLiveVideo(callback, delay) {
    if (!isLivePage() || Number(delay) < 5000) return false;
    const source = typeof callback === "function" ? Function.prototype.toString.call(callback) : String(callback || "");
    return interruptionTimer.test(source);
  }

  window.setTimeout = function (callback, delay, ...args) {
    if (blocksLiveVideo(callback, delay)) return 0;
    return nativeSetTimeout(callback, delay, ...args);
  };

  window.setInterval = function (callback, delay, ...args) {
    if (blocksLiveVideo(callback, delay)) return 0;
    return nativeSetInterval(callback, delay, ...args);
  };
})();
