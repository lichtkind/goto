use v6.c;
use lib IO::Path.new($?FILE).dirname;
use YAMLish;
use Table;

my $VERSION = 0.042;
my %kommando = (add => 'a', replace => 'r', move => 'm', delete => 'd',
                name => 'n', sort => 's', # alter, letztbesucht, oft besucht,  dir , kürzel, order
                undo => 'u', last => '.', help => 'h');

my %file = (places => 'places.yaml', destination => 'last_choice');

my $start-dir = IO::Path.new(".").absolute; # dir I started in | $*CWD.path;
chdir IO::Path.new($?FILE).dirname;


my (%destination, %table);
%table<main> = Table.new(keys => <dir created visited visits shortcut>);
%destination<pos> = (load-yamls slurp %file<places>)[0];
my %dir_by_shortcut = collect_shortcuts(%destination<pos>);

my $param = shift @*ARGS;
interpret-input($param) if $param.defined;

loop {
    display-list(%destination<pos>);
    interpret-input( prompt '>' ); 
}

sub interpret-input($in) {
    given $in {
        when /^\-/ {interpret-command($in.substr(1))}
        when %kommando<last>      { save(); exit(0) } # get last dir from <visited>
        when ''                   { goto-dir('.'); }
        default                   { goto($in) }
    }
}

sub interpret-command($cmd){
    given $cmd {
        when /$(%kommando<add>)\s*(\d*)(\:\w+)?/ {
            # $*CWD.path;
            for 0 .. %destination<pos>.end -> $pos {
                return say "! dir $start-dir already stored on pos $pos" if %destination<pos>[$pos]<dir> eq $start-dir;
            }
            my $pos = ($/[0].Str and %destination<pos>[$/[0]]:exists) ?? $/[0] !! %destination<pos>.elems;
            %destination<pos>.splice( $pos, 0, {dir => $start-dir, created => time, visited => 0, visits => 0, shortcut => $/[1]});
        }
        when /$(%kommando<delete>)\s*(\w+)/ {
            my ($dir, $err) = pos-or-shortcut-to-path($/[0]);
            if $err { say $err; proceed; }
            
        }
        default { help() }
    }
}


sub display-list (@places, $sort? = 'nr') {
    say "pos. and shortcuts of dest. dir in user defined order, exit with enter, -%kommando<help> gets help";
    if $sort eq 'nr' {
        for @places.kv -> $nr, $place {
            $place.<shortcut> //= '';
            say "[$nr]\t $place.<shortcut>\t $place.<dir>";
        }
    }    
}

sub collect_shortcuts(@places) { map({$_<shortcut> => $_}, @places).Hash }

sub pos-or-shortcut-to-path ($adr) {
    if $adr ~~ /^\d+$/ {
        return (%destination<pos>[$adr]<dir>,'') if %destination<pos>[$adr]:exists;
        return ('', "$adr is not an index between 0 and "~ %destination<pos>.end);
    } else {
        return (%dir_by_shortcut{$adr}<dir>,'') if %dir_by_shortcut{$adr}:exists;
        return ('', "$adr is not a known shortcut like: {%dir_by_shortcut.keys}");
    }            
}

sub goto ($adr)   {
    my ($dir, $err) = pos-or-shortcut-to-path($adr);
    $err ?? say "can not go to  directory $adr \n$err" !! goto-dir($dir);
}
sub goto-dir ($dir) {
    for |%destination<pos> -> $place {
        if $place<dir> eq $dir {
                $place<visited> = time;
                $place<visits>++;
        }
    }
    save();
    spurt %file<destination>, $dir;
    exit();
}

sub save { spurt %file<places>, save-yaml %destination<pos> }

sub help {
    print qq:to/EOH/;
          <Enter>           complete command, no command - just exit
          %kommando<last>                 goto dir visited last time
          <pos>             goto dir on position - positions are listed in first column
          <abk>             goto dir with shortcut - short names are right beside position, 2nd column
          <adr>             refer to dir by <pos> or <abk>
          -%kommando<add>\[<pos>\]\[:<abk>\] add current dir - last pos. is default
          -%kommando<replace>\<adr>\[:<abk>\]   replace dir with current one
          -%kommando<name>\<adr>\[:<abk>\]   set shortcut name for a dir (1-5 chars)
          -%kommando<move>\<adr>-><pos>    move dir to new position (right argument)
          -%kommando<delete>\<adr>           delete dir - last pos. is default
          -%kommando<sort>-\<how>          sort list by: ps-position cd-created vd-visited vs-nr of visits
                                          dp-dir-path sc-shortcut name   prepend r for reverse
          -%kommando<undo>                undo last change
          -%kommando<help>                display this help text
      EOH
}
=pod
TODO:
=cut
