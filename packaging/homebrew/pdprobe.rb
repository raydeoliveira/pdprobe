class Pdprobe < Formula
  desc "Read USB-C Power Delivery profiles from KM003C and FNB58 meters"
  homepage "https://www.raymonddeoliveira.com/software#pdprobe"
  version "0.2.0"
  license :cannot_represent

  on_macos do
    depends_on arch: :arm64
    depends_on macos: :sonoma
    url "https://github.com/raydeoliveira/pdprobe/releases/download/v0.2.0/pdprobe-0.2.0-macos-arm64.tar.gz"
    sha256 "1eed70ba8c9e3b364a751d3c7fc97c543b7504ed340f9c44086ef67ce1a1e2b8"
  end

  on_linux do
    depends_on arch: :x86_64
    url "https://github.com/raydeoliveira/pdprobe/releases/download/v0.2.0/pdprobe-0.2.0-linux-x86_64.tar.gz"
    sha256 "5e1dec78192deb11850dae2f07e5251f5ff4a3d14bc3778672e95f149ec5f857"
  end

  def install
    bin.install "pdprobe"
    bin.install_symlink "pdprobe" => "pdctl"
    lib.install "libpdprobe.a" if File.exist?("libpdprobe.a")
    include.install Dir["include/*.h"] if Dir.exist?("include")
    (pkgshare/"udev").install "99-pdprobe.rules" if File.exist?("99-pdprobe.rules")
    doc.install "README.md", "LICENSE", "SECURITY.md", "SKILL.md", "server.json"
  end

  test do
    assert_match "pdprobe 0.2.0", shell_output("#{bin}/pdprobe --version")
    assert_match "pdprobe 0.2.0", shell_output("#{bin}/pdctl --version")
    describe_json = shell_output("#{bin}/pdprobe --describe")
    assert_match "\"schema_version\":1", describe_json
    assert_match "\"km003c\"", shell_output("#{bin}/pdprobe probe --sim --json")
    assert_match "\"dry_run\":true", shell_output("#{bin}/pdprobe trigger --sim --voltage-mv 9000 --dry-run --json")
  end
end
