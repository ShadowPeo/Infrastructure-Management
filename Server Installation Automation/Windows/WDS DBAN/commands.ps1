
https://www.scribd.com/document/265423330/How-to-Implement-DBAN-in-a-WDS-Server
https://dermeph.wordpress.com/2010/08/26/boot-dban-with-wds/

mkdir D:\WDSBackup\Boot
mkdir D:\WDSBackup\Boot\X86
mkdir D:\WDSBackup\Boot\X64

cd D:\RemoteInstall\Boot\x86
cp .\abortpxe.com .\abortpxe.0
cp .\pxeboot.n12 .\pxeboot.0
cp .\abortpxe.com mkdir D:\WDSBackup\Boot\X86\abortpxe.0
cp .\pxeboot.n12 mkdir D:\WDSBackup\Boot\X86\pxeboot.0


cd D:\RemoteInstall\Boot\x64
cp .\abortpxe.com .\abortpxe.0
cp .\pxeboot.n12 .\pxeboot.0
cp .\abortpxe.com D:\RemoteInstall\Boot\x64abortpxe.0
cp .\pxeboot.n12 D:\RemoteInstall\Boot\x64pxeboot.0

#Download and Extract SysLinux
curl https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.zip -outfile C:\SysLinux.zip
Expand-Archive -LiteralPath C:\SysLinux.zip -DestinationPath C:\SysLinux\

#Downmload and Extract DBAN
curl https://nchc.dl.sourceforge.net/project/dban/dban/dban-2.3.0/dban-2.3.0_i586.iso -outfile C:\DBAN.iso
$mount = Mount-DiskImage -ImagePath "C:\DBAN.iso" -ErrorAction "Ignore"
$volume = Get-DiskImage "C:\DBAN.iso" | Get-Volume
$source = $volume.DriveLetter + ":\*"
$folder = mkdir "C:\DBAN"
$cpparams = @{Path = $source; Destination = $folder; Recurse = $true;}
cp @cpparams
$hide = Dismount-DiskImage -ImagePath "C:\DBAN.iso" -ErrorAction "Ignore"

