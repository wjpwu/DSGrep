#!/usr/bin/perl
##############################################################################
#
# Program:     ParseDSX.pl
#
# Description: See ShowBlurb function below for details
#
# === Modification History ===================================================
# Date       Author           Comments
# ---------- --------------- -------------------------------------------------
# 07-18-2002 Steve Boyce     Created.
# 08-21-2002 Steve Boyce     Exporting routines now includes binary info.
# 08-28-2002 Steve Boyce     Corrected bug relating to jobs and routines
#                            located in the root folder.  They now get
#                            created in the correct location.
# 08-28-2002 Steve Boyce     Changed default output directory to be the name
#                            of the dsx file being parsed without the
#                            extension.
#                            -s option now works.
# 10-04-2002 Steve Boyce     Eliminated -c option.  That now the default
#                            and only behavior.
#                            Default Parmameter metadata is now stripped out
#                            of all jobs except any jobs that have PROTOTYPE
#                            or Batch:UTIL in the name.
#                            Routines are unaffected.
# 11-12-2002 Steve Boyce     Added Version dipsplay option.
#                            Corrected source code generation bug.
# 02-27-2003 Steve Boyce     Added -x option to strip out ValidationStatus
# 03-21-2003 Steve Boyce     Stripping out ValidationStatus is now default
#                            behavior.
# 04-29-2003 Steve Boyce     Bumped version number
#
##############################################################################

use Getopt::Std;
use File::Basename;
my $version="2.1.00";

##############################################################################
sub ShowBlurb
{
print <<ENDOFBLURB;
Syntax:      ParseDSX.pl -h -l<ListFile> -o<OutputDir> -s -v -y <DSXFile>

Version:     $version

Description: Extracts individual jobs and routines from a DataStage export
             file.

Parameters:  <DSXFile> Name of DataStage DSX file to parse.  This file is
                       assumed to be generated from the DataStage export
                       process.

Options:     -l  job/routine list file. (future enhancement)
                 This file contains a list of jobs and routines to extract
                 from the <DSXFile>.
             -o  Explicitly specify <OutputDir> directory.
                 Default is the name of the parsed dsx file without the
                 extension in the current directory.
             -s  Extract job "Job Control Code" and routine "source"
                 code into "source files".
                 <job>.src and <routine>.src
                 These will appear in the same directory as the generated
                 dsx files in the <OutputDir> directory.
             -v  Display version information.
             -y  Force a "Yes" answer to overwrite existing <OutputDir>
                 directory prompt.
             -h  This help.

Notes:       Job and routine names are case sensitive in DataStage.  Extracted
             jobs and routines are placed in file names constructed based on
             job or routine names.  Running this utility on the Windows
             platform will ignore case and possibly consider some jobs and
             routines duplicates when the UNIX platform will not.
             It is a good practice to not rely on case as a differentiator
             for file names.
ENDOFBLURB
}

##############################################################################
sub ShowVersion
{
print <<ENDOFBLURB;
ParseDSX.pl Version $version
ENDOFBLURB
}

##############################################################################
sub DieWith
{
   my ($MessageLine) = @_;
   print "$MessageLine\nType ParseDSX.pl -h for help.\n";
   exit 1;
}

##############################################################################
sub OKToOverWriteOutputDir
{
   my ($OutPutDirectory, $opt_y) = @_;
   my $RetVal = 0;

   if ( -e $OutPutDirectory ) {
      if ( $opt_y ) {
         print "*** Warning: <OutputDir> directory ($OutPutDirectory) already exists.  Using anyway.\n";
         $RetVal = 1;
      }
      else  {
         print "*** Warning: <OutputDir> directory ($OutPutDirectory) already exists.\n";
         print "Proceed anyway? [y|n] ";
         $Ans = <STDIN>;
         chomp($Ans) if ($Ans);
         if ( "$Ans" eq "Y" || "$Ans" eq "y" ) {
            $RetVal = 1;
         }
         else  {
            DieWith("Aborting.");
         }
      }
   }
   else  {
      if ( MakeDir($OutPutDirectory, 777) ) {
         $RetVal = 1;
      }
      else  {
         DieWith("Error: Could not create ($OutPutDirectory) directory");
      }
   }
   return $RetVal;
}

##############################################################################
sub LoadObjectList
{
   my ($DSXListFile) = @_;
   my %DSXObjectList = ();

   if ( $DSXListFile ) {
      if (open fhDSXListFile, "<".$DSXListFile) {
         while (<fhDSXListFile>) {
            chop;
            #-- Push line onto array
            $DSXObjectList{$_} = 1;
         }
         close fhDSXListFile;
      }
      else  {
         DieWith("Error: Can't open $DSXListFile");
      }
      while ( ($key,$value) = each %DSXObjectList ) {
         print "$key=$value\n";
      }
   }
   return %DSXObjectList;
}

##############################################################################
sub MakeDir
{
   my ($FullDirPath, $Mode) = @_;
   my @DirList = ();
   my $PartialDirPath = "";
   my $RetVal = 1;

   $FullDirPath =~ tr/\\/\//;
   @DirList = split(/\//,$FullDirPath);
   foreach $Directory ( @DirList ) {
      $PartialDirPath = $PartialDirPath . $Directory. "/" ;
      if ( ! (length($PartialDirPath) == 3 && substr($PartialDirPath, 1, 2) eq ":/") ) {
         if ( ! -e $PartialDirPath ) {
            if ( ! mkdir($PartialDirPath, $Mode) ) {
               $RetVal = 0;
            }
         }
      }
   }
   return $RetVal;
}

##############################################################################
sub ParseQuotedString
{
   my ($InputLine) = @_;
   my $FirstQuotePos = 0;
   my $SecondQuotePos = 0;
   my $Length = 0;

   $FirstQuotePos = index($InputLine, '"');
   $SecondQuotePos = index($InputLine, '"', $FirstQuotePos+1);
   $Length = $SecondQuotePos - $FirstQuotePos;

   return substr($InputLine, $FirstQuotePos + 1, $Length - 1);
}

##############################################################################
sub MakeDuplicateName
{
   my ($OriginalName) = @_;
   my $NewName = "";
   my $DupSuffix = 1;

   $NewName = $OriginalName . "_dup" . "$DupSuffix";
   while ( -e $NewName ) {
      if ( $DupSuffix > 99 ) {
         DieWith("Error: There seems to be more than 99 duplicate jobs or routines.\n");
      }
      $DupSuffix += 1;
      $NewName = $OriginalName . "_dup" . "$DupSuffix";
   }
   return $NewName;
}

##############################################################################
sub WriteDSXHeader
{
   my ($fhOutputFile) = @_;

   print $fhOutputFile "BEGIN HEADER\n";
   print $fhOutputFile "   CharacterSet \"ENGLISH\"\n";
   print $fhOutputFile "   ExportingTool \"Ardent DataStage Export\"\n";
   print $fhOutputFile "   ToolVersion \"3\"\n";
   print $fhOutputFile "   ServerName \"$cStandardServerName\"\n";
   print $fhOutputFile "   ToolInstanceID \"$cStandardToolInstanceID\"\n";
   print $fhOutputFile "   MDISVersion \"1.0\"\n";
   print $fhOutputFile "   Date \"$cStandardDate\"\n";
   print $fhOutputFile "   Time \"$cStandardTime\"\n";
   print $fhOutputFile "END HEADER\n";
}

##############################################################################
sub WriteDSXObjectFile
{
   my ($ObjectType, $tmpDSXObjectHolder, $OutPutDirectory, $DSXObjectName, $DSXCategoryName) = @_;
   my $x = 0;
   my $TranslatedDSXObjectName = "";
   my $TranslatedCategorytName = "";
   my $OutputFileName = "";
   my $OutputLine = "";
   my $WriteLine = 1;

   $TranslatedDSXObjectName = $DSXObjectName;
   $TranslatedDSXObjectName =~ tr/:/_/;
   $TranslatedDSXObjectName =~ tr/ /_/;

   if ($ObjectType eq "JOB") {
      $OutPutDirectory = $OutPutDirectory . "/jobs";
      if ( ! -e $OutPutDirectory ) {
         if ( ! MakeDir($OutPutDirectory, 777) ) {
            DieWith("Error: Could not create directory: $OutPutDirectory");
         }
      }
   }
   else  {
      $OutPutDirectory = $OutPutDirectory . "/routines";
      if ( ! -e $OutPutDirectory ) {
         if ( ! MakeDir($OutPutDirectory, 777) ) {
            DieWith("Error: Could not create directory: $OutPutDirectory");
         }
      }
   }

   if ($DSXCategoryName) {
      $TranslatedCategoryName = $DSXCategoryName;
      $TranslatedCategoryName =~ tr/ /_/;

      $TranslatedCategoryName =~ tr/\\/\//s;

      $OutPutDirectory = $OutPutDirectory . "/" . $TranslatedCategoryName;
      if ( ! -e $OutPutDirectory ) {
         if ( ! MakeDir($OutPutDirectory, 777) ) {
            DieWith("Error: Could not create directory: $OutPutDirectory");
         }
      }
   }
   $OutputFileName = $OutPutDirectory . "/" . $TranslatedDSXObjectName . ".dsx";

   print "Writing File: $OutputFileName...\n";

   if ( -e $OutputFileName ) {
      print "*** WARNING: Job/Routine output DSX file ($OutputFileName) already exists.  Creating duplicate.\n";
      $OutputFileName = MakeDuplicateName($OutputFileName);
   }

   if (open (fhOutputFile, ">$OutputFileName")) {
      WriteDSXHeader(\*fhOutputFile);
      if ($ObjectType eq "ROUTINE") {
         print fhOutputFile "BEGIN DSROUTINES\n";
      }
      while ( $$tmpDSXObjectHolder[$x] ) {
         $OutputLine = $$tmpDSXObjectHolder[$x];
         $WriteLine = 1;
         #-- Filter ValidationStatus metadata out
         #-- This metadata seems to be intermitent with no value added.
         if ($OutputLine =~ /^.*ValidationStatus /) {
            $WriteLine = 0;
         }
         if ($WriteLine) {
            #-- Normalize dates and times
            if ($OutputLine =~ /^ {3,6}DateModified /) {
               $OutputLine =~ s/\".{10}\"/\"$cStandardDate\"/;
            }
            else  {
               if ($OutputLine =~ /^ {3,6}TimeModified /) {
                  $OutputLine =~ s/\".{8}\"/\"$cStandardTime\"/;
               }
            }
            #-- Send the line to the output file
            print fhOutputFile "$OutputLine";
         }
         $x = $x + 1;
      }
      if ($ObjectType eq "ROUTINE") {
         print fhOutputFile "END DSROUTINES\n";
      }
      close fhOutputFile;
   }
}

##############################################################################
sub WriteDSXSourceFile
{
   my ($ObjectType, $tmpDSXObjectSourceHolder, $OutPutDirectory, $DSXObjectName, $DSXCategoryName) = @_;
   my $x = 0;
   my $TranslatedDSXSourceName = "";
   my $TranslatedCategorytName = "";
   my $OutputFileName = "";
   my $OutputLine = "";

   $TranslatedDSXSourceName = $DSXObjectName;
   $TranslatedDSXSourceName =~ tr/:/_/;
   $TranslatedDSXSourceName =~ tr/ /_/;

   if ($ObjectType eq "JOB") {
      $OutPutDirectory = $OutPutDirectory . "/jobs";
      $SourceKeyword = "JobControlCode";
   }
   else  {
      $OutPutDirectory = $OutPutDirectory . "/routines";
      $SourceKeyword = "Source";
   }

   if ($DSXCategoryName) {
      $TranslatedCategoryName = $DSXCategoryName;
      $TranslatedCategoryName =~ tr/ /_/;
      $TranslatedCategoryName =~ tr/\\/\//s;

      $OutPutDirectory = $OutPutDirectory . "/" . $TranslatedCategoryName;
   }
   $OutputFileName = $OutPutDirectory . "/" . $TranslatedDSXSourceName . ".src";

   if ( -e $OutputFileName ) {
      $OutputFileName = MakeDuplicateName($OutputFileName);
   }

   #-- Convert single line encoded source code to properly formated code
   #-- Chop off trailing 6 spaces after every CR-LF (really leading 6 spaces)

   #-- Convert "symbolic CR-LF to real CR-LF
   $tmpDSXObjectSourceHolder =~ s/\\\(D\)\\\(A\)/\n/g;

   #-- Chop off leading keyword - either Source " or JobControlCode "
   $tmpDSXObjectSourceHolder =~ s/^ *$SourceKeyword "//;

   #-- Chop off trailing quote
   $tmpDSXObjectSourceHolder =~ s/\" *$//;

   #-- Replace all \" with "
   $tmpDSXObjectSourceHolder =~ s/\\\"/\"/g;

   #-- replace all \\ with \
   $tmpDSXObjectSourceHolder =~ s/\\\\/\\/g;

   if (open (fhOutputFile, ">$OutputFileName")) {
      print fhOutputFile $tmpDSXObjectSourceHolder;
      close fhOutputFile;
   }
}

##############################################################################
sub OKToStripDefaultValue
{
   my ($DSXObjectName, $DSParameterName) = @_;
   my $RetVal = 0;

   if (! ($DSXObjectName =~ /Batch::UTIL/) ) {
      if (! ($DSXObjectName =~ /PROTOTYPE/) ) {
         if (! ($DSParameterName eq "JobName" or $DSParameterName eq "PartitionNumber" or $DSParameterName eq "PartitionCount" ) ) {
            $RetVal = 1;
         }
      }
   }
   return $RetVal
}

##############################################################################
sub ParseDSXObjects
{
   my ($DSXFileName, $Greppize, $OutPutDirectory, $DSXObjectList) = @_;
   my @tmpDSXObjectHolder = ();
   my $tmpDSXObjectSourceHolder = "";
   my $DSXObjectName = "";
   my $DSXCategoryName = "";
   my $InDSJobBlock = 0;;
   my $InDSRoutineBlock = 0;
   my $InDSRecordBlock = 0;
   my $InDSSubRecordBlock = 0;
   my $InDSUBinaryBlock = 0;
   my $DSParameterName = "";

   if (open fhDSXFileName, "<".$DSXFileName) {
      while (<fhDSXFileName>) {
         if ($InDSJobBlock) {
            push(@tmpDSXObjectHolder, $_);
            if ($_ =~ /^END DSJOB/) {
               $InDSJobBlock = 0;
               WriteDSXObjectFile("JOB", \@tmpDSXObjectHolder, $OutPutDirectory,
                                  $DSXObjectName, $DSXCategoryName);
               if ( $tmpDSXObjectSourceHolder ) {
                  WriteDSXSourceFile("JOB", $tmpDSXObjectSourceHolder, $OutPutDirectory,
                                     $DSXObjectName, $DSXCategoryName);
               }
            }
            else  {
               if ($InDSRecordBlock) {
                  if ($_ =~ /^   END DSRECORD/) {
                     $InDSRecordBlock = 0;
                  }
                  else {
                     if ($InDSSubRecordBlock) {
                        if ($_ =~ /^      END DSSUBRECORD/) {
                           $InDSSubRecordBlock = 0;
                        }
                        else {
                           if ($_ =~ /^         Name/) {
                              $DSParameterName = ParseQuotedString($_);
                           }
                           if ($_ =~ /^         Default/) {
                              if (OKToStripDefaultValue($DSXObjectName, $DSParameterName)) {
                                 pop(@tmpDSXObjectHolder);
                              }
                           }
                        }
                     }
                     else {
                        if ($_ =~ /^      BEGIN DSSUBRECORD/) {
                           $InDSSubRecordBlock = 1;
                        }
                        else  {
                           if ($_ =~ /^      Category /) {
                              $DSXCategoryName = ParseQuotedString($_);
                           }
                           if ($Greppize) {
                              if ($_ =~ /^      JobControlCode /) {
                                 $tmpDSXObjectSourceHolder = $_;
                              }
                           }
                        }
                     }
                  }
               }
               else  {
                  if ($_ =~ /^   BEGIN DSRECORD/) {
                     $InDSRecordBlock = 1;
                  }
                  else  {
                     if ($_ =~ /^   Identifier /) {
                        $DSXObjectName = ParseQuotedString($_);
                     }
                  }
               }
            }
         }
         else {
            if ($InDSRoutineBlock) {
               if ($_ =~ /^END DSROUTINES/) {
                  $InDSRoutineBlock = 0;
               }
               else  {
                  if ($InDSRecordBlock) {
                     push(@tmpDSXObjectHolder, $_);
                     if ($_ =~ /^   END DSRECORD/) {
                        $InDSRecordBlock = 0;
                     }
                     else  {
                        if ($_ =~ /^      Identifier /) {
                           $DSXObjectName = ParseQuotedString($_);
                        }
                        else  {
                           if ($_ =~ /^      Category /) {
                              $DSXCategoryName = ParseQuotedString($_);
                           }
                           if ($Greppize) {
                              if ($_ =~ /^      Source /) {
                                 $tmpDSXObjectSourceHolder = $_;
                              }
                           }
                        }
                     }
                  }
                  else  {
                     if ($InDSUBinaryBlock) {
                        push(@tmpDSXObjectHolder, $_);
                        if ($_ =~ /^   END DSUBINARY/) {
                           $InDSUBinaryBlock = 0;
                           WriteDSXObjectFile("ROUTINE", \@tmpDSXObjectHolder, $OutPutDirectory,
                                              $DSXObjectName, $DSXCategoryName);
                           if ( $tmpDSXObjectSourceHolder ) {
                              WriteDSXSourceFile("ROUTINE", $tmpDSXObjectSourceHolder, $OutPutDirectory,
                                                 $DSXObjectName, $DSXCategoryName);
                           }
                        }
                        else  {
                           if ($_ =~ /^      COMMENT Record is empty/) {
                              print "*** WARNING: Routine ($DSXObjectName) is missing compiled executable.\n";
                           }
                        }
                     }
                     else  {
                        if ($_ =~ /^   BEGIN DSRECORD/) {
                           $InDSRecordBlock = 1;
                           @tmpDSXObjectHolder = ();
                           push(@tmpDSXObjectHolder, $_);
                           $tmpDSXObjectSourceHolder = "";
                           $DSXCategoryName = "";
                        }
                        else  {
                           if ($_ =~ /^   BEGIN DSUBINARY/) {
                              $InDSUBinaryBlock = 1;
                              push(@tmpDSXObjectHolder, $_);
                           }
                        }
                     }
                  }
               }
            }
            else  {
               if ($_ =~ /^BEGIN DSJOB/) {
                  $InDSJobBlock = 1;
                  @tmpDSXObjectHolder = ();
                  push(@tmpDSXObjectHolder, $_);
                  $tmpDSXObjectSourceHolder = "";
                  $DSXCategoryName = "";
               }
               else  {
                  if ($_ =~ /^BEGIN DSROUTINES/) {
                     $InDSRoutineBlock = 1;
                  }
               }
            }
         }
      }
      close (fhDSXFileName);
   }
}

##############################################################################
# Main

#-- Global variables (constants)
$cStandardDate = "2001-01-01";
$cStandardTime = "01.00.00";
$cStandardServerName = "ServerName";
$cStandardToolInstanceID = "ToolInstanceID";

#-- Local variables
my %DSXObjectList = ();
my $NumArgs = 0;
my $DSXFileName = "";
my $OutPutDirectory = "";
my $Ans = "";

if (getopts('hl:o:svy')) {
   if ( $opt_h ) {
      ShowBlurb();
      exit 2;
   }
   if ( $opt_v ) {
      ShowVersion();
      exit 2;
   }
   $NumArgs = scalar(@ARGV);
   if ( $NumArgs == 1 ) {
      $DSXFileName = $ARGV[0];
      if ( -r $DSXFileName ) {
         if ( $opt_o ) {
            $OutPutDirectory = $opt_o;
         }
         else  {
            $OutPutDirectory = basename($DSXFileName, ".dsx");
         }
         if ( OKToOverWriteOutputDir($OutPutDirectory, $opt_y) ) {
            %DSXObjectList = LoadObjectList($opt_l);
            ParseDSXObjects($DSXFileName, $opt_s, $OutPutDirectory, \@DSXObjectList);
         }
      }
      else  {
         DieWith("Error: Unable to read file ($DSXFileName).");
      }
   }
   else  {
      DieWith("Error: Invalid filespec.");
   }
}
else  {
   DieWith("Error: Invalid options.");
}