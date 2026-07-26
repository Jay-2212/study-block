const releaseEndpoint =
  "https://api.github.com/repos/Jay-2212/study-block/releases/latest";

const setReleaseVersion = (version) => {
  document.querySelectorAll("[data-release-version]").forEach((element) => {
    element.textContent = version;
  });
};

const loadLatestRelease = async () => {
  try {
    const response = await fetch(releaseEndpoint, {
      headers: { Accept: "application/vnd.github+json" },
    });

    if (!response.ok) {
      throw new Error(`GitHub release request failed: ${response.status}`);
    }

    const release = await response.json();
    if (typeof release.tag_name === "string" && release.tag_name.trim()) {
      setReleaseVersion(release.tag_name);
    }
  } catch {
    setReleaseVersion("Latest release");
  }
};

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
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.12 },
  );

  elements.forEach((element) => observer.observe(element));
};

document.querySelector("[data-current-year]").textContent =
  new Date().getFullYear();

revealElements();
loadLatestRelease();
