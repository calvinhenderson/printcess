export const DropdownHook = {
  mounted() {
    // element was added to DOM
    this.el.addEventListener("keydown", (event) => this.key_event(event));
  },

  key_event(event) {
    // We have to get the container element on key events because it doesn't exist until there is data.
    const container = document.getElementById(this.el.getAttribute("data-dropdown-root"));
    if (!container) return;

    ["focus"].forEach(event => {
      container.addEventListener(event, () => {
        container.classList.remove("hidden");
      });
    });

    // Get the top-most level child of the dropdown container
    let el = document.activeElement;
    while (container && container.contains(el) && el && el.parentElement != container) { el = el.parentElement; }

    switch (event.key) {
      case "Escape": {
        container.classList.add("hidden");
      } break;
      case " ":
      case "Enter":
        el.click();
        this.el.nextElementSibling.focus();
        container.classList.add("hidden");
        break;
      case "ArrowUp": {
        if (!container.contains(el)) break;

        let prev = el.previousElementSibling;
        if (prev != null) {
          prev.focus();
        }
      } break;
      case "ArrowDown": {
        let next = el.nextElementSibling;
        if (!container.contains(el)) {
          console.log("focusing first dropdown element.")
          next = container.firstElementChild;
        } else {
          console.log("container", container, "contains", el);
        }
        if (next != null) {
          next.focus();
        }
      } break;
    }
  },
};


