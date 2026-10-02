window.Phronova = {
    events: {},
    reactives: {}
};

document.addEventListener("click", function (event) {
    const element =
        event.target.closest("[data-phronova-event-click]");

    if (!element) {
        return;
    }

    const eventId =
        element.getAttribute("data-phronova-event-click");

    fetch("/__phronova_event/" + eventId);
});

setInterval(async function () {
    const response =
        await fetch("/__phronova_reactive_updates");

    const text =
        await response.text();

    for (const line of text.trim().split("\n")) {
        if (!line) {
            continue;
        }

        const separator =
            line.indexOf("|");

        const id =
            line.substring(0, separator);

        const value =
            line.substring(separator + 1);

        const element =
            document.querySelector(
                '[data-phronova-reactive="' + id + '"]'
            );

        if (element) {
            element.textContent = value;
        }
    }
}, 5);