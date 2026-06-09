(function () {
  try {
    var id = "ai-warning-banner";
    if (document.getElementById(id)) return;

    var banner = document.createElement("div");
    banner.id = id;
    banner.textContent = "AI tools may be in use. Follow company policy.";

    Object.assign(banner.style, {
      position: "fixed",
      top: "0",
      left: "0",
      right: "0",
      backgroundColor: "#d9534f",
      color: "#ffffff",
      padding: "10px",
      fontSize: "14px",
      fontWeight: "700",
      textAlign: "center",
      zIndex: "2147483647",
      fontFamily: "Arial, sans-serif",
      pointerEvents: "none"
    });

    document.documentElement.appendChild(banner);
  } catch (e) {
    console.error("Banner injection failed");
  }
})();
