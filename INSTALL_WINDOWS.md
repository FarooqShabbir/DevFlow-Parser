# Installing Build Tools on Windows

To build and run the DevFlow DSL parser on Windows, you need to install:
- **Bison** - Parser generator
- **Flex** - Lexical analyzer generator  
- **GCC** - C compiler
- **Make** (optional, but recommended)

## Option 1: MSYS2 (Recommended)

MSYS2 provides a Unix-like environment on Windows with a package manager.

### Steps:

1. **Download and install MSYS2**
   - Download from: https://www.msys2.org/
   - Install to default location (e.g., `C:\msys64`)

2. **Open MSYS2 UCRT64 terminal**
   - Search for "MSYS2 UCRT64" in Start Menu
   - Or navigate to `C:\msys64\ucrt64.exe`

3. **Install required packages:**
   ```bash
   pacman -Syu
   pacman -S bison flex gcc make
   ```

4. **Add MSYS2 to PATH (optional):**
   - Add `C:\msys64\ucrt64\bin` to your Windows PATH
   - Or use MSYS2 terminal directly

5. **Build the project:**
   ```bash
   cd /d/Fast/TPL/Project
   make
   ```

## Option 2: WSL (Windows Subsystem for Linux)

WSL provides a full Linux environment on Windows.

### Steps:

1. **Install WSL:**
   ```powershell
   wsl --install
   ```
   Or follow: https://docs.microsoft.com/en-us/windows/wsl/install

2. **Open WSL terminal** and install packages:
   ```bash
   sudo apt-get update
   sudo apt-get install bison flex gcc make
   ```

3. **Build the project:**
   ```bash
   cd /mnt/d/Fast/TPL/Project
   make
   ```

## Option 3: MinGW-w64

MinGW-w64 provides GCC compiler for Windows.

### Steps:

1. **Download MinGW-w64:**
   - Download from: https://www.mingw-w64.org/downloads/
   - Or use installer from: https://sourceforge.net/projects/mingw-w64/

2. **Install MSYS2** (see Option 1) as it includes MinGW-w64

3. **Add to PATH:**
   - Add MinGW-w64 `bin` directory to PATH
   - Example: `C:\mingw64\bin`

## Option 4: Chocolatey (Quick Install)

If you have Chocolatey package manager:

```powershell
choco install bison flex gcc make
```

## Option 5: Using Build Script (Manual Build)

If you have bison, flex, and gcc installed but not make:

```cmd
build.bat
```

This will:
- Generate parser from `devflow.y`
- Generate lexer from `devflow.l`
- Compile and link to create `devflow_parser.exe`

## Verification

After installation, verify tools are available:

```bash
bison --version
flex --version
gcc --version
make --version
```

## Building and Running

Once tools are installed:

```bash
# Build
make

# Or manually
make clean
make all

# Run parser with test file
./devflow_parser test_pipeline.devflow
# On Windows (without make):
devflow_parser.exe test_pipeline.devflow
```

## Troubleshooting

### "bison: command not found"
- Ensure bison is in your PATH
- Try using MSYS2 or WSL terminal directly

### "flex: command not found"  
- Ensure flex is in your PATH
- Install flex package in your environment

### "gcc: command not found"
- Install GCC compiler
- Check PATH includes compiler bin directory

### Linking errors with -lfl
- On Windows, you may not need `-lfl` flag
- Try building without it (see `build.bat`)

### Permission denied
- On Windows, ensure you're running as administrator if needed
- Or use MSYS2/WSL terminal

## Quick Start with WSL (Recommended for Beginners)

```powershell
# 1. Install WSL (if not already installed)
wsl --install

# 2. Restart computer if prompted

# 3. Open WSL terminal and run:
sudo apt-get update
sudo apt-get install bison flex gcc make

# 4. Navigate to project:
cd /mnt/d/Fast/TPL/Project

# 5. Build:
make

# 6. Test:
./devflow_parser test_pipeline.devflow
```

