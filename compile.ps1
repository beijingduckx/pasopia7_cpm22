function DoCpm{
    param(
        $arg
    )
    $arg = './cpm ' + $arg
    $output = Invoke-Expression $arg
    
    '----'
    $arg
    $output

    if($output -match '[0-9]+ Fatal error'){
        Pop-Location
        Exit
    }
}

function WriteDiskImage{
    param(
        [Array]$disk,
        [Array]$data,
        $diskOffset,
        $dataOffset,
        $size
    )
    for($i = 0; $i -lt $size; $i++){
        $disk[$diskOffset + $i] = $data[$dataOffset + $i]
    }
}

push-Location .

cd build

# create source link
try{
    New-Item -ItemType HardLink -Path . -Target ../bootp7.z80 -Name bootp7.z80
    New-Item -ItemType HardLink -Path . -Target ../pasopia7.z80 -Name pasopia7.z80
    New-Item -ItemType HardLink -Path . -Target ../cpm22.z80 -Name cpm22.z80
}
catch{
    Pop-Location
    Exit
}

$orgDiskFile = 'cpm_base.2d'
$targetDiskFile = 'cpm.2d'

$biosBinFile = 'pasopia7.bin'
$bootBinFile = 'bootp7.bin'
$ccpBinFile = 'cpm22.bin'

# build
try{
    DoCpm 'm80 bootp7.rel,bootp7.prn=bootp7.z80'
    DoCpm ('l80 bootp7.rel,' + $bootBinFile + '/n/e')
    DoCpm 'm80 pasopia7.rel,pasopia7.prn=pasopia7.z80'
    DoCpm ('l80 pasopia7.rel,' + $biosBinFile + '/n/e')
    DoCpm 'm80 cpm22.rel,cpm22.prn=cpm22.z80/z'
    DoCpm ('l80 cpm22.rel,' + $ccpBinFile + '/n/e')
}
catch{
    '** Assembly error'
    Pop-Location
    Exit
}

# deploy disk image
$pwd = Get-Location
$diskPath = $pwd.Path + '\' + $orgDiskFile
$bootPath = $pwd.Path + '\' + $bootBinFile
$biosPath = $pwd.Path + '\' + $biosBinFile
$ccpPath = $pwd.Path + '\' + $ccpBinFile

try{
    $disk = [System.IO.File]::ReadAllBytes($diskPath)
    $pbios = [System.IO.File]::ReadAllBytes($biosPath)
    $ccp = [System.IO.File]::ReadAllBytes($ccpPath)
    $boot = [System.IO.File]::ReadAllBytes($bootPath)
}
catch{
    '** Bin file load error'
    Pop-Location
    Exit
}

$bootLen = $boot.Length
$bootDiskOffset = 0x2000  # track1, side 0, sector=1
$bootBinOffset = 0

WriteDiskImage $disk $boot $bootDiskOffset $bootBinOffset $bootLen

$biosLen = $pbios.Length
$biosDiskOffset = 0x1000   # track 0, side 1, sector=1
$biosBinOffset = 0

WriteDiskImage $disk $pbios $biosDiskOffset $biosBinOffset $biosLen

#$ccpLen = 0x15e0
#$ccpDiskOffset = 0x2200    # track1, side 0, sector=3
#$ccpBinOffset = 0x880

$ccpLen = $ccp.Length
$ccpDiskOffset = 0x2200    # track1, side 0, sector=3
$ccpBinOffset = 0

WriteDiskImage $disk $ccp $ccpDiskOffset $ccpBinOffset $ccpLen

$diskPath = $pwd.Path + '\' + $targetDiskFile

[System.IO.File]::WriteAllBytes($diskPath, $disk)

Pop-Location
