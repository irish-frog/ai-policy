(function () {
  const id = "company-ai-warning-banner";
  if (document.getElementById(id)) return;

  const banner = document.createElement("div");
  banner.id = id;
  banner.textContent = "COMPANY POLICY: DO NOT SHARE CONFIDENTIAL INFORMATION WITH AI TOOLS";

  Object.assign(banner.style, {
    position: "fixed",
    top: "0",
    left: "0",
    width: "100%",
    height: "25px",
    lineHeight: "25px",
    background: "#b91c1c",
    color: "#ffffff",
    fontSize: "12px",
    fontWeight: "600",
    textAlign: "center",
    zIndex: "2147483647",
    fontFamily: "Arial, sans-serif",
    pointerEvents: "none"
  });

  document.documentElement.appendChild(banner);
})();
