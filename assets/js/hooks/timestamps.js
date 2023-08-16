function computedTimeString(iso8601_timestamp) {
  const timestamp = Date.parse(iso8601_timestamp);
  const now = Date.now();
  const diff = Math.floor((now - timestamp) / 1000);

  console.log(iso8601_timestamp, timestamp, now, diff);

  if (diff < 60) return diff + "s"; // seconds
  if (diff < 3600) return diff % 60 + "m"; // minutes
  if (diff < 86400) return diff % 3600 + "h"; // hours
  return diff % 86400 + "d"; // days
}

export default {
  mounted() {
    // element was added to DOM
    console.log("connected timestamp hook");
    this.timerId = setInterval(() => this.updateTimestamps(), 1000);
  },

  destroyed() {
    console.log("disconnected timestamp hook");
    clearInterval(this.timerId);
  },

  updateTimestamps() {
    this.el
      .querySelectorAll("[data-timestamp]")
      .forEach(el => {
        el.innerText = computedTimeString(el.getAttribute("data-timestamp"));
      });
  }
};
