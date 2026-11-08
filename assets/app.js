// Viewer logic for the preview page
const doc = document.getElementById("doc");
const POLL_MS = 200;
const MAX_POLL_MS = 4000;
const DISCONNECTED_AT = 10; // failures in a row before showing a notice
let version = null,
  lastLine = null,
  theme = null,
  failures = 0,
  delay = POLL_MS,
  noticeShown = false;

async function get(path) {
  const r = await fetch(path, { cache: "no-store" });
  if (!r.ok) throw new Error(path + " " + r.status);
  return r;
}

// Scroll so the block containing the cursor line sits near the top of the window.
// Falls back to a fraction of the document if no source positions are present.
function scrollToLine(line, total) {
  const blocks = doc.querySelectorAll("[data-sourcepos]");
  if (blocks.length) {
    let target = null;
    for (const el of blocks) {
      if (parseInt(el.dataset.sourcepos, 10) > line) break;
      target = el;
    }
    if (target) {
      const top = target.getBoundingClientRect().top + scrollY;
      window.scrollTo(0, top - innerHeight * 0.3);
    }
    return;
  }
  const max = document.documentElement.scrollHeight - innerHeight;
  window.scrollTo(0, (line / total) * max);
}

// Clicks never navigate this window: it has no address bar, so navigation would
// strand the preview. Links to files are followed by Neovim itself; http(s)
// links open in your normal browser via vim.ui.open.
doc.addEventListener("click", (e) => {
  const a = e.target.closest("a[href]");
  if (!a) return;
  const href = a.getAttribute("href") || "";
  if (!href || href.startsWith("#")) return;
  if (/^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith("//")) {
    if (!/^https?:/i.test(href) && !href.startsWith("//")) return;
    e.preventDefault();
    fetch("/follow?open=" + encodeURIComponent(href), { cache: "no-store" }).catch(() => {});
    return;
  }
  e.preventDefault();
  const target = href.replace(/[?#].*$/, "");
  fetch("/follow?path=" + encodeURIComponent(target), { cache: "no-store" }).catch(() => {});
});

// The server is gone when Neovim exits or the preview is stopped. Say so
// instead of freezing silently, but keep polling with backoff in case the
// session comes back.
function showEnded() {
  if (noticeShown) return;
  noticeShown = true;
  doc.innerHTML =
    '<h1>Preview ended</h1><p>The preview server stopped or Neovim exited. This window is safe to close.</p>';
}

async function poll() {
  try {
    const st = await (await get("/state")).json();
    failures = 0;
    delay = POLL_MS;
    if (noticeShown) {
      noticeShown = false;
      doc.innerHTML = "";
    }
    if (st.name && st.name !== document.title) document.title = st.name;
    // Re-fetch the stylesheet when the look changes, without a page reload.
    if (st.theme && st.theme !== theme) {
      theme = st.theme;
      const link = document.querySelector('link[rel="stylesheet"]');
      if (link) link.href = "/markdown.css?v=" + Date.now();
    }
    // Fetch the body only when the version changed.
    if (st.version !== version) {
      version = st.version;
      doc.innerHTML = await (await get("/body")).text();
    }
    // Scroll only when the cursor moved, so manual scrolling sticks.
    if (st.line !== lastLine) {
      lastLine = st.line;
      scrollToLine(st.line, st.total);
    }
  } catch (e) {
    ++failures;
    if (failures >= DISCONNECTED_AT) showEnded();
    delay = Math.min(delay * 2, MAX_POLL_MS);
  }
  setTimeout(poll, delay);
}
poll();
