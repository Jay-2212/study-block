const revealElements = () => {
  const elements = document.querySelectorAll("[data-reveal]");

  if (
    !("IntersectionObserver" in window) ||
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  ) {
    elements.forEach((element) => element.classList.add("is-visible"));
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.12 },
  );

  elements.forEach((element) => observer.observe(element));
};

const applyRelease = (tag, downloadUrl, checksum) => {
  document.querySelectorAll("[data-release-version]").forEach((element) => {
    element.textContent = tag;
  });
  document.querySelectorAll("[data-download-link]").forEach((element) => {
    element.setAttribute("href", downloadUrl);
  });
  if (!checksum) return;
  const checksumNode = document.querySelector(".release-checksum code");
  if (checksumNode) {
    checksumNode.textContent = checksum;
  }
};

const loadLatestRelease = () => {
  fetch("https://api.github.com/repos/Jay-2212/study-block/releases/latest")
    .then((response) => {
      if (!response.ok) throw new Error("release lookup failed");
      return response.json();
    })
    .then((release) => {
      const assets = Array.isArray(release.assets) ? release.assets : [];
      const dmg = assets.find((asset) => asset.name === "StudyBlock.dmg");
      if (!release.tag_name || !dmg) return;
      applyRelease(release.tag_name, dmg.browser_download_url);
      const checksumAsset = assets.find(
        (asset) => asset.name === "StudyBlock.dmg.sha256",
      );
      if (!checksumAsset) return;
      return fetch(checksumAsset.browser_download_url).then((response) => {
        if (!response.ok) return;
        return response.text().then((text) => {
          const hash = text.trim().split(/\s+/)[0];
          if (hash) applyRelease(release.tag_name, dmg.browser_download_url, hash);
        });
      });
    })
    .catch(() => {});
};

document.querySelector("[data-current-year]").textContent =
  new Date().getFullYear();

revealElements();
loadLatestRelease();
