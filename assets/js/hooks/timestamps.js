function computedTimeString(iso_start, iso_end) {
  const start = new Date(iso_start);
  const end = new Date(iso_end);
  const diff = Math.floor((end - start) / 1000);

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
        let end = Date.now();

        if (el.getAttribute("data-timestamp-end")) {
          end = el.getAttribute("data-timestamp-end");
        }
        el.innerText = computedTimeString(el.getAttribute("data-timestamp"), end);
      });
  }
};
