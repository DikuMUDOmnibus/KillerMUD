#!/usr/bin/perl -w

use strict;

my %config = (
	'test_koniec_pliku'    => 1,
	'test_nazwa_pliku'     => 1,
	'test_poczatek_player' => 1,
);
$config{'number_of_tests'}    = 0;
$config{'dir'}                = '/staff/mud/mud/player';
$config{'show_damaged_files'} = 1;
$config{'move_damaged_files'} = 0;


print "\nSprawdzanie plik�w graczy.\n\n";
print sprintf "Dla katalogu: %s\n", $config{'dir'};
unless (-d $config{'dir'}) {
	die("\nPrzerywam prac�! - Podano nieprawid�owy katalog!\n\n");
}
print "Sprawdzam: \n";
foreach (sort keys %config) {
	if ($_ =~ /^test_/) {
		my $name = $_;
		$name =~ s/test_//;
		$name =~ s/_/ /g;
		print sprintf "%18s: %s\n", $name, ($config{$_})? 'tak':'nie';
		$config{'number_of_tests'}++ if $config{$_};
	}
}
print "\n";

if ($config{'number_of_tests'}){
	my @files;

	if (opendir DIR, $config{'dir'}) {
		@files = sort grep {/^[A-Z][a-z]+$/ && -f $config{'dir'}.'/'.$_} readdir(DIR);
		close DIR;
	}

	my $message = '';
	my $errors = 0;

	print "Sprawdzam plik, prosz� czeka�:  ";
	foreach my $filename (@files) {
		if (open my $read_fh, '<', $config{'dir'}.'/'.$filename) {
			my $correct = 1;
			my $test = <$read_fh>;
			#
			# pierwsza linijka jest prawid�owa
			#
			if ($correct && $config{'test_poczatek_pliku_player'}){
				unless ($test =~ /^#PLAYER\n/) {
					$errors++ if $correct;
					$message .= $config{'dir'}.'/'.$filename."\n";
					$correct = 0;
				}
			}
			#
			# testy dotycz�ce drugiej lini pliku gracza
			#
			if ($correct && $config{'test_poczatek_player'} ) {
				$test = <$read_fh>;
				#
				# sprawdzanie czy pierwsza linijka ma prawid�ow� posta�
				#
				if ($test =~ /^Name ([A-Z][a-z]+)~\n/) {
					$test = $1;
					#
					# sprawdzanie czy nazwa pliku zgadza si� z imieniem gracza
					#
					if ($correct) {
						unless ($test eq $filename) {
							$errors++ if $correct;
							$message .= $config{'dir'}.'/'.$filename."\n";
							$correct = 0;
						}
					}
				}
				else {
					$errors++ if $correct;
					$message .= $config{'dir'}.'/'.$filename."\n";
					$correct = 0;
				}
			}
			#
			# sprawdzanie czy na ko�cu pliku mamy string '#END'
			#
			if ($correct && $config{'test_koniec_pliku'}) {
				seek $read_fh, -5, 2;
				$test = <$read_fh>;
				unless ($test =~ /^#END\n/) {
					$errors++ if $correct;
					$message .= $config{'dir'}.'/'.$filename."\n";
					$correct = 0;
				}
			}
		}
	}
	print"\n\n";
	print sprintf "Wszystkich plik�w: %d\n", $#files;
	if ($message) {
		print sprintf "Uszkodzonych plik�w: %d\n\n", $errors;
		print "Uszkodzone pliki:\n";
		print $message if $config{'show_damaged_files'};
		if ($config{'move_damaged_files'}){
			print "\nPrzenosz� uszkodzone plik!\n";
			unless (-d $config{'dir'} . '/damaged') {
				mkdir $config{'dir'}.'/damaged';
			}
			my $command = 'mv '.$message.' '.$config{'dir'} . '/damaged' ;
			$command =~ s/\n/ /g;
			system( $command);
		}
	}
	else {
		print "Brak uszkodzonych plik�w.\n";
	}
}
else {
	print "Brak test�w do wykonania.\n";
}
print"\n";
