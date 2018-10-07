class MoltenVk < Formula
  desc "Implementation of the Vulkan graphics and compute API on top of Metal"
  homepage "https://github.com/KhronosGroup/MoltenVK"
  url "https://github.com/KhronosGroup/MoltenVK/archive/v1.0.20.tar.gz"
  sha256 "57e78893f0d255c2c257607117def1e7216d574b5ad835d225591dc374a8bba8"

  depends_on "cmake" => :build
  # Requires IOSurface/IOSurfaceRef.h.
  depends_on :macos => :sierra

  # MoltenVK depends on very specific revisions of its dependencies.
  # For each resource the path to the file describing the expected
  # revision is listed.
  resource "cereal" do
    # ExternalRevisions/cereal_repo_revision
    url "https://github.com/USCiLab/cereal.git",
        :revision => "51cbda5f30e56c801c07fe3d3aba5d7fb9e6cca4"
  end

  resource "glslang" do
    # ExternalRevisions/glslang_repo_revision
    url "https://github.com/KhronosGroup/glslang.git",
        :revision => "1323bf8e39fa17da3e0901a4b1ab5dfd61ee5460"
  end

  resource "spirv-cross" do
    # ExternalRevisions/SPIRV-Cross_repo_revision
    url "https://github.com/KhronosGroup/SPIRV-Cross.git",
        :revision => "6fd66664e8bdadd3f6281aad711f771ef9c24bbe"
  end

  resource "vulkan-headers" do
    # ExternalRevisions/Vulkan-Headers_repo_revision
    url "https://github.com/KhronosGroup/Vulkan-Headers.git",
        :revision => "db09f95ac00e44149f3894bf82c918e58277cfdb"
  end

  resource "vulkan-tools" do
    # ExternalRevisions/Vulkan-Tools_repo_revision
    url "https://github.com/KhronosGroup/Vulkan-Tools.git",
        :revision => "ca05ec7c9706eb2949e489b4719fe499b0059d36"
  end

  resource "spirv-tools" do
    # External/glslang/known_good.json
    url "https://github.com/KhronosGroup/SPIRV-Tools.git",
        :revision => "714bf84e58abd9573488fc365707fb8f288ca73c"
  end

  resource "spirv-headers" do
    # External/glslang/known_good.json
    url "https://github.com/KhronosGroup/SPIRV-Headers.git",
        :revision => "ff684ffc6a35d2a58f0f63108877d0064ea33feb"
  end

  def install
    (buildpath/"External/cereal").install resource("cereal")
    (buildpath/"External/glslang").install resource("glslang")
    (buildpath/"External/glslang/External/spirv-tools").install resource("spirv-tools")
    (buildpath/"External/glslang/External/spirv-tools/external/SPIRV-Headers").install resource("spirv-headers")
    (buildpath/"External/SPIRV-Cross").install resource("spirv-cross")
    (buildpath/"External/Vulkan-Headers").install resource("vulkan-headers")
    (buildpath/"External/Vulkan-Tools").install resource("vulkan-tools")

    cd "External/Vulkan-Headers" do
      system "cmake", ".", *std_cmake_args
      system "make", "install"
    end

    mkdir "External/glslang/build" do
      # Required due to files being generated during build.
      system "cmake", "..", *std_cmake_args
      system "make", "-C", "External/spirv-tools/source"
    end

    xcodebuild "-project", "MoltenVKPackaging.xcodeproj", "-scheme", "MoltenVK (Release)", "build"

    frameworks.install "Package/Release/MoltenVK/macOS/MoltenVK.framework"
    lib.install "Package/Release/MoltenVK/macOS/libMoltenVK.dylib"
    frameworks.install "Package/Release/MoltenVKShaderConverter/MoltenVKGLSLToSPIRVConverter/macOS/MoltenVKGLSLToSPIRVConverter.framework"
    frameworks.install "Package/Release/MoltenVKShaderConverter/MoltenVKSPIRVToMSLConverter/macOS/MoltenVKSPIRVToMSLConverter.framework"
    bin.install "Package/Release/MoltenVKShaderConverter/Tools/MoltenVKShaderConverter"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <vulkan/vulkan.h>

      int main(void)
      {
        const char *extensionNames[] = { "VK_KHR_surface" };

        VkInstanceCreateInfo instanceCreateInfo = {
          VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL,
          0, NULL,
          0, NULL,
          1, extensionNames,
        };

        VkInstance inst;
        vkCreateInstance(&instanceCreateInfo, NULL, &inst);

        return 0;
      }
    EOS
    system ENV.cc, "-o", "test", "test.cpp", "-L#{lib}", "-lMoltenVK"
    system "./test"
  end
end
