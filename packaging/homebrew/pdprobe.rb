class Pdprobe < Formula
  desc "C17 USB-C PD/PPS auditor, telemetry reader & trigger CLI + MCP server"
  homepage "https://github.com/raydeoliveira/pdprobe"
  version "0.1.0"
  license :cannot_represent

  on_macos do
    depends_on arch: :arm64
    depends_on macos: :sonoma
    url "https://github.com/raydeoliveira/pdprobe/releases/download/v0.1.0/pdprobe-0.1.0-macos-arm64.tar.gz"
    sha256 "e4327b9f949769ffcdbfb355e5671a1e89b902042408834589200547e61ba332"
  end

  on_linux do
    url "https://github.com/raydeoliveira/pdprobe/releases/download/v0.1.0/pdprobe-0.1.0-linux-x86_64.tar.gz"
    sha256 "4add419b76bd80b0f13d9794b809893586096c20aa08c37d3d928f1980aa4bcc"
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
    assert_match "pdprobe 0.1.0", shell_output("#{bin}/pdprobe --version")
    assert_match "pdprobe 0.1.0", shell_output("#{bin}/pdctl --version")
    describe_json = shell_output("#{bin}/pdprobe --describe")
    assert_match "\"schema_version\":1", describe_json
    assert_match "\"km003c\"", shell_output("#{bin}/pdprobe probe --sim --json")
    assert_match "\"dry_run\":true", shell_output("#{bin}/pdprobe trigger --sim --voltage-mv 9000 --dry-run --json")
  end
end
