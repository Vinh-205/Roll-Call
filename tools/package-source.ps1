param([string]$OutputName='TruongTuanVinh_2380602577_RollCall_source.zip')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
$root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$outDir=Join-Path $root 'deliverables'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
if([IO.Path]::GetFileName($OutputName) -ne $OutputName){throw 'OutputName must be a file name.'}
$target=Join-Path $outDir $OutputName
$skipDirs=@('build','.dart_tool','.idea','.git','deliverables','node_modules','.wrangler','.sites-runtime','dist','outputs','.vinext','.next','.gradle','.kotlin','.cxx','.agents','.codex')
$skipNames=@('BAT_DAU_DEMO.md','KICH_BAN_DEMO.md','LOI_LONG_TIENG_DEMO.txt','NOP_BAI.txt','KIEM_THU_THIET_BI_THAT.md','RA_SOAT_YEU_CAU.md','hovaten.txt','hoten.txt','TruongTuanVinh.txt','.private.env','.email-setup.json','.flutter-plugins-dependencies','local.properties','next-env.d.ts','GeneratedPluginRegistrant.java')
$stream=[IO.File]::Open($target,[IO.FileMode]::Create)
$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
$count=0
try {
 $queue=[Collections.Generic.Stack[IO.DirectoryInfo]]::new();$queue.Push([IO.DirectoryInfo]::new($root))
 while($queue.Count){
  $directory=$queue.Pop()
  foreach($item in $directory.EnumerateFileSystemInfos()){
   if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){continue}
   if($item -is [IO.DirectoryInfo]){if($item.Name -notin $skipDirs){$queue.Push($item)};continue}
   if($item.Name -in $skipNames -or $item.Name -like '.dev.vars*' -or $item.Name -like '.env*' -or $item.Extension -in @('.iml','.tsbuildinfo','.log')){continue}
   $relative=$item.FullName.Substring($root.Length+1).Replace('\','/')
   $entry=$zip.CreateEntry($relative,[IO.Compression.CompressionLevel]::Optimal)
   $inputFile=[IO.File]::OpenRead($item.FullName);$outputFile=$entry.Open()
   try{$inputFile.CopyTo($outputFile)}finally{$inputFile.Dispose();$outputFile.Dispose()}
   $count++
  }
 }
}finally{$zip.Dispose();$stream.Dispose()}
Write-Output "Packaged $count source files into $target"

