#!/usr/bin/env perl
 
use strict;
use warnings;
use Spreadsheet::WriteExcel::FromXML;

my $xml=$ARGV[0];;
my $xls=$ARGV[1];;

#my $fromxml = Spreadsheet::WriteExcel::FromXML->new( "file.xml" );
#$fromxml->parse;
#$fromxml->buildSpreadsheet;
#$fromxml->writeFile("file.xls");
# or
#my $data = $fromxml->getSpreadsheetData;
  # then write $data to a file...or do with it as you wish

  # or, even simpler:
#my $data = Spreadsheet::WriteExcel::FromXML->BuildSpreadsheet( "file.xml" );

  # or, even simpler:
Spreadsheet::WriteExcel::FromXML->XMLToXLS( "$xml", "$xls" );
