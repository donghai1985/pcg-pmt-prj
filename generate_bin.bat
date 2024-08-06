@echo off
set /p version=Input version:
echo %version%

set scriptDir=%~dp0


xcopy %scriptDir%project_1\project_1.runs\impl_1\mfpga_top.bit %scriptDir%version_bin\pmt_version\
xcopy %scriptDir%project_1\project_1.runs\impl_1\mfpga_top.ltx %scriptDir%version_bin\pmt_version\
xcopy %scriptDir%project_1\project_1.runs\impl_1\mfpga_top.bin %scriptDir%version_bin\pmt_version\

ren %scriptDir%version_bin\pmt_version\mfpga_top.bit PCG_PMTM_v%version%.bit 
ren %scriptDir%version_bin\pmt_version\mfpga_top.ltx PCG_PMTM_v%version%.ltx 
ren %scriptDir%version_bin\pmt_version\mfpga_top.bin PCG_PMTM_v%version%.bin 

pause