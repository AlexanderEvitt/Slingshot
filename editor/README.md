Slingshot uses Godot v4.5. Because it incorporates both .NET and large world coordinates, a custom build of the editor is required. Below are the steps for doing that, assuming you have all the prerequisites installed (e.g. SCons). Documentation is linked.

1. Clone the github ([Getting source](https://docs.godotengine.org/en/4.4/contributing/development/compiling/getting_source.html#doc-getting-source)).

```
git clone https://github.com/godotengine/godot.git -b 4.4
```

2. Compile with SCons, both the editor and release templates. ([Compiling for Windows](https://docs.godotengine.org/en/4.4/contributing/development/compiling/compiling_for_windows.html))

```
scons platform=windows target=editor module_mono_enabled=yes precision=double
scons platform=windows target=template_debug module_mono_enabled=yes precision=double
scons platform=windows target=template_release module_mono_enabled=yes precision=double
```

3. Generate the glue. ([Compiling with .NET](https://docs.godotengine.org/en/4.4/contributing/development/compiling/compiling_with_dotnet.html))

```
<godot_binary> --headless --generate-mono-glue modules/mono/glue
# e.g:
bin\godot.windows.editor.double.x86_64.mono.exe --headless --generate-mono-glue modules\mono\glue
```

4. Build the managed libraries

```
# cd into godot (root folder) first
python .\modules\mono\build_scripts\build_assemblies.py --godot-output-dir ./bin --push-nupkgs-local C:\Users\alexa\MyLocalNugetSource --precision=double
```







n. Create Windows export templates (or other platforms).


