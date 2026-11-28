import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken }
})

topbar.config({ barColors: { 0: "#F7C843" }, shadowColor: "rgba(11, 57, 56, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Print a receipt from a hidden iframe so the cashier never leaves the POS.
// The receipt page autoprints itself on load.
window.addEventListener("phx:print_receipt", ({ detail }) => {
  document.getElementById("receipt-print-frame")?.remove()
  const frame = document.createElement("iframe")
  frame.id = "receipt-print-frame"
  frame.style.cssText = "position:fixed;left:-10000px;top:0;width:400px;height:800px;border:0"
  frame.src = detail.url
  document.body.appendChild(frame)
})

liveSocket.connect()
window.liveSocket = liveSocket
