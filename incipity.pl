#!/usr/bin/perl -w

# distributed under Opensource New BSD License

use CGI qw/:all/;

# definicie regularnych vyrazov pre jednotlive polia kvoli formalnej kontrole
#my $pat_a = '^0[1-9]$';
#my $pat_b = '^01$';
#my $pat_c = '^01$';
#my $pat_d = '^.+$';
#my $pat_2 = '^pe$';
#my $pat_g = '^[FCGg][-+][1-5]$';
#my $pat_n = '^(xF(C(G(D(A(E(H?)?)?)?)?)?)?|bB(E(A(D(G(C(F?)?)?)?)?)?)?|)$';
#my $pat_o = '^[co]\.?|c/|c?\d+|c?\d+/\d+$';
#my $pat_r = '^(([A-Ga-g][xb]?)+|{[1-9]|1[0-2]}+)$';

# trvania not pae => lilypond
my %dlzka = ("0" => "\\longa", "9" => "\\breve", "6" => "16", "3" => "32", "5" => "64", "7" => "128");

# predznamenania
my %key = ("F" => "g", "FC" => "d", "FCG" => "a", "FCGD" => "e", "FCGDA" => "b", "FCGDAE" => "fis", "FCGDAEB" => "cis",
           "B" => "f", "BE" => "bes", "BEA" => "es", "BEAD" => "as", "BEADG" => "des", "BEADGC" => "ges", "BEADGCF" => "ces");

# kluce
my %clef = ("G2" => "treble", "C1" => "soprano", "C2" => "mezzosoprano", "C3" => "alto", "C4" => "tenor", "C5" => "baritone",
            "G1" => "french", "F3" => "varbaritone", "F4" => "bass", "F5" => "subbass", "g1" => "french_8", "g2" => "treble_8");

my $q = new CGI;

print $q->header(-type => 'text/html', -charset => 'UTF-8', -expires => 'now');

print $q->start_html(-title => "ShowPE",
                     -bgcolor => "white",
                     -text => "black",
                     -expires => 'now',
                     -head => [meta({-http_equiv => 'Pragma', -content => 'no-cache'}),
                               meta({-http_equiv => 'Cache-Control', -content => 'no-cache'}),
                               meta({-http_equiv => 'Expires', -content => 'Sun, 06 Nov 1994 08:49:37 GMT'})],
                     -style => {-src => 'http://www.mzk.cz/mzk.css'},
                     -lang => 'cs_CZ',
                     -encoding => "UTF-8");

print $q->h1("Zobrazení hudebních incipitů");

print $q->start_form(-name => "form");

print $q->br, "<b>Zadejte pole 031:</b><br/> 
   (napr.:000166812 031   L \$\$a01\$\$b01\$\$c01\$\$dAllegro\$\$mvl 1\$\$gG-2\$\$nbB\$\$oc\$\$p''2A8GFGA/4FCCC/2A8GFGA/2.F\$\$rF\$\$2pe)",
      $q->br, $q->textfield("incipit", "", 130), $q->br,
      $q->submit({-name => "submit", -Value => 'Zobraz'}), $q->br, $q->end_form, $q->br;

if ($q->param("incipit"))
{
$incipit = $q->param("incipit");

chomp $incipit;

$incipit =~ s/^.*?\$\$(.*)/$1/;

# rozhodenie pola 031 na jednotlive podpolia pre dalsie spracovanie
@incipit = split(/\$\$/, $incipit);

@pozicia = grep (/^[abc]/, @incipit);
($polem) = grep (/^m/, @incipit);
$polem =~ s/^.//;
($poleo) = grep (/^o/, @incipit);
$poleo =~ s/^.//;
($poled) = grep (/^d/, @incipit);
$poled =~ s/^.//;
($poler) = grep (/^r/, @incipit);
$poler =~ s/^.//;

$text1 = "$polem, $poleo $poled; $poler";

foreach $i (sort @pozicia)
{
    $i = substr $i, 1;
    $pozicia .= $i . ".";
}

$pozicia =~ s/\.$//;

chdir "/var/www/www.mzk.cz/incipity";
system "rm -f *";

open LYSUB, ">/var/www/www.mzk.cz/incipity/source.ly";

print LYSUB qq{\\version "2.10.16" \n};
print LYSUB "\\markup{ \\fontsize #3 { $pozicia     $text1 } }\n";
#print LYSUB "\\markup {text1}\n";
print LYSUB "{\n";
print LYSUB "\\autoBeamOff\n";
print LYSUB "\\set fontSize = #2\n";

# prechadzame vsetky podpolia a tie relevantne spracujeme v prislusnej funkcii
print "<pre>";
print "Converting to lilypond...\n";
foreach $i (sort @incipit)
{
    $i =~ /(.)(.*)/;
    ($nazov, $hodnota) = ($1, $2);
    #$pattern = "pat_" . $nazov;
    #print STDERR "Chyba v podpoli $nazov" unless $hodnota =~ /${$pattern}/;
    &{"spracuj_" . $nazov}($hodnota) if $nazov =~ /[dgnopt]/; # volanie funkcie pre jednotlive podpolia
}

print LYSUB "\\markup { \\fontsize #4 {$text2} }\n";
#print LYSUB "\\markup {text3}\n";
close LYSUB;

my $temp = int(rand 10000000) + 1;
system "/home/staff/kamzo/bin/lilypond source.ly 2>&1 " || die "chyba konverzie";
print "Converting to png...\n";
#system "/home/staff/kamzo/bin/a2ping.pl source.ps PNG:obrazok_$temp.png";
system "/usr/bin/convert -quality 95 source.ps obrazok_$temp.png";
print "Done";
print "</pre>";

print qq{<br><img src="http://bupu.mzk.cz/incipity/obrazok_$temp.png">};

print $q->end_html;


sub spracuj_d
{
    $rychlost = shift;

}

sub spracuj_g
{
# vlozenie kluca na zaklade asociativneho pola definovaneho vyssie
    $kluc = shift;

    $kluc =~ s/[-+]//;
    #$kluc =~ s/g(.)/G${1}_8/;

    print LYSUB qq|\\clef "$clef{$kluc}"\n|;
}

sub spracuj_n
{
# vlozenie predznamenania na zaklade asociativneho pola definovaneho vyssie
    $key = shift;
    $signature = $key;
    $key = substr $key, 1;

    print LYSUB "\\key $key{$key} \\major\n" if ($key{$key});
}

sub spracuj_o
{
# vlozenie rytmusu
    $rytmus = shift;
    
    print LYSUB "\\time $rytmus\n" unless $rytmus =~ /^c/;
    print LYSUB "\\time 2/2\n" if $rytmus eq "c/";

    $rytmus = "2/2" if ($rytmus =~ /^c/);
}

sub spracuj_t
{
# pridanie textu skladby pod notovu osnovu 
# vzhladom na formu zapisu nie je mozne napasovat to spravne pod jednotlive
# noty, kedze v texte nie su nijak vyznacene jednotlive pauzy...
    $text2 = shift;

    $text2 =~ s/\=/"="/g; # znak = uzavrieme do uvodzoviek
    
    #print LYSUB "\\addlyrics { $text }\n";
}

sub spracuj_p
{
# spracovanie notoveho zapisu incipitu
#
# vypneme kontroly a automatickeho pocitania a vkladania taktovych ciar pre 
# pripad predtaktia
    print LYSUB "\\cadenzaOn";
    $cadenza = 1;

# notovy incipit, ktory budeme prechadzat sekvencne a postupne skracovat
    $inc = shift;

# nastavenie defaultnej oktavy a tempa
    $oktava = "'";
    $tempo = "4";
    $dlzka = "4";

# znasobenie opakovanej casti a odstranenie znacky opakovania
    while ($inc =~ /!.*!ff/)
    {
        $inc =~ s/!(.*?)!ff/$1!$1!f/;
    }
    $inc =~ s/!(.*?)!f/$1/;

# kym incipit cely neprejdeme a neskratime ho na nulovy retazec, vzdy pozrieme 
# zaciatok, spravime akciu podla toho, co tam je a spracovany retazec zo zaciatku
# odrezeme
    while (length $inc > 0)
    {
        SWICH:
        {
# zmena oktavy
            $inc =~ /^[',]+/ && do
            {
                $oktava = $&;
                $inc = substr $inc, length($oktava);
                $oktava =~ s/,$//;
                last SWICH;
            };
# zmena dlzky noty
            $inc =~ /^(\d)(\.*)/ && do
            {
                $tempo = $&;
                $dlzka = $1;
                $inc = substr $inc, length($tempo);
                $tempo = $dlzka{$dlzka} . $2 if(exists $dlzka{$dlzka});
                last SWICH;
            };
# pripad grace notes o viac notach
            $inc =~ /^gg|^qq/ && do
            {
                $grace = $&;
                $inc = substr $inc, 2;
                $grace = ($grace eq "gg") ? "acciaccatura { " : "appoggiatura { ";
                $beam = "["; # spravime nad notami tramec
                $gracenote = "1"; # a zaznamename si, ze tvorime nejake grace notes
                print LYSUB " \\$grace";
                last SWICH;
            };
# ukoncenie grace notes o viac notach
            $inc =~ /^r/ && do
            {
                $inc = substr $inc, 1;
                print LYSUB "] } ";# ukoncime tramec nad notami
                $gracenote = "0";# skoncili sme s grace note
                last SWICH;
            };
# grace notes o jednej note
            $inc =~ /^[gq]/ && do
            {
                $grace = $&;
                $inc = substr $inc, 1;
                $grace = ($grace eq "g") ? "acciaccatura" : "appoggiatura";
                print LYSUB " \\$grace";
                $xgrace = 1;
                last SWICH;
            };
# predznamenanie (krizik/sharp, becko/flat)
            $inc =~ /^[xb]+/ && do
            {
                $acc = $&;
                $inc = substr $inc, length($acc);
                $acc =~ s/x/is/g;
                $acc =~ s/b/es/g;
                last SWICH;
            };
# odrazky (naturals)
            $inc =~ /^n/ && do
            {
                $inc = substr $inc, 1;
                $natural = 1;
                last SWICH;
            };
# fermata
            $inc =~ /^\(.\)/ && do
            {
                $inc =~ s/^.(.)./$1/;
                $fermata = 1;
                last SWICH;
            };
# trioly
            $inc =~ /^\(\{?([',\d]*)[xnb]?[CDEFGAHB][',]*[xnb]?[CDEFGAHB][',]*[xnb]?[CDEFGAHB]\}?\)/ && do
            #$inc =~ /^\(\{?[CDEFGAHB]{3}\}?\)/ && do
            {
                print LYSUB " \\times 2/3 {";
                $inc = substr $inc, 1;
                last SWICH;
            };
# kvartoly, kvintoly...
            $inc =~ /^\(\{?[CDEFGAHBxnb',\d]+\}?;(\d)\)/ && do
            {
                $temp = $1 - 1;
                print LYSUB " \\times $temp/$1 {";
                $inc =~ s/^\((\{?[CDEFGAHBxnb]+\}?);(\d)\)/$1\)/;
                last SWICH;
            };
# ukoncenie trioly
            $inc =~ /^\)\}/ && do
            {
                print LYSUB "] }";
                $inc = substr $inc, 2;
                last SWICH;
            };
            $inc =~ /^\)/ && do
            {
                print LYSUB " }";
                $inc = substr $inc, 1;
                last SWICH;
            };
# zaciatok tramca nad notami
            $inc =~ /^{/ && do
            {
                $beam = "[";
                $inc = substr $inc, 1;
                last SWICH;
            };
# koniec tramca nad notami
            $inc =~ /^}/ && do
            {
                $inc = substr $inc, 1;
                print LYSUB "]";
                last SWICH;
            };
# taktove ciary
            $inc =~ /^[\/\:]+/ && do
            {
                $bar = $&;
                $inc = substr $inc, length($bar);
                $bar =~ s/\//|/g;
                $bar =~ s/:\/\//:\//;
                $bar =~ s/\/\/:/\/:/;
                print LYSUB qq{ \\bar "$bar"};
                # ak mame prvy takt, mame vypnutu kontrolu taktovych ciar, tak ju zasa zapneme
                if ($cadenza)
                {
                    print LYSUB " \\cadenzaOff";
                    $cadenza = 0;
                }
                %note = (); # vymazeme docasne predznamenania, ktore platia do konca taktu
                last SWICH;
            };
# zapis samotnej noty
            $inc =~ /^[CDEFGAB]/ && do
            {
                $nota = $&;
                $inc = substr $inc, 1;
                delete $note{"$nota$oktava"} if ($natural);
                $nota = $note{"$nota$oktava"} if ($note{"$nota$oktava"} && !$acc);
                if ($acc)
                {
                    $note{"$nota$oktava"} = "$nota$acc";
                }
                if ($signature =~ /$nota/)
                {
                    $acc .= ($signature =~ /^x/ ? "is" : "es");
                    $acc = substr $acc, 0, 4;
                }
                $acc = "" if ($natural);
                $nota =~ tr/CDEFGAB/cdefgab/;
                print LYSUB " $nota$acc$oktava";
                if ($gracenote || $xgrace)
                {
                    print LYSUB "16";
                }else
                {
                    print LYSUB "$tempo";
                }
                if ($rychlost)
                {
                    #print LYSUB "^\\markup{ \\bigger { $rychlost } }";
                    $rychlost = "";
                }
                print LYSUB "$beam" unless ($xgrace);
                print LYSUB "\\fermata" if ($fermata);
                $acc = "";
                $natural = "";
                $beam = "" unless ($xgrace);
                $xgrace = "";
                $fermata = "";
                last SWICH;
            };
# zapis pauzy
            $inc =~ /^\-/ && do
            {
                $inc = substr $inc, 1;
                print LYSUB " r$tempo";
                print LYSUB "\\fermata" if ($fermata);
                $fermata = "";
                last SWICH;
            };
# zapis viactaktovej pauzy
            $inc =~ /^=(\d*)/ && do
            {
                $rest = $&;
                $inc = substr $inc, length($rest);
                $rest =~ s/=//;
                # v pripade vypnutej kontroly a automatickeho vkladania taktovych ciar sa 
                # viactaktova pauza nezobrazi korektne, tak ju zasa zapneme
                if ($cadenza)
                {
                    print LYSUB " \\cadenzaOff";
                    $cadenza = 0;
                }
                print LYSUB " \\set Score.skipBars = ##t \\override MultiMeasureRest #'expand-limit = 1 R1*$rytmus*$rest";
                last SWICH;
            };
# tie (legatura?) 
            $inc =~ /^\+/ && do
            {
                print LYSUB "~";
                $inc = substr $inc, 1;
                last SWICH;
            };
            $inc = substr $inc, 1;
        }
    }
    print LYSUB "}\n";

    #print LYSUB "\n";
}

}
