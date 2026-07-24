(function () {
  "use strict";

  const nativeSetTimeout = window.setTimeout.bind(window);
  const nativeSetInterval = window.setInterval.bind(window);
  const interruptionTimer = /(loginmodal|login_modal|signinmodal|sign_in_modal|watchlimit|watch_limit|continuewatching|continue_watching|openappmodal|open_app_modal)/i;

  function blocksLiveVideo(callback, delay) {
    if (!/^\/@[^/]+\/live\/?$/.test(location.pathname) || Number(delay) < 5000) return false;
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
