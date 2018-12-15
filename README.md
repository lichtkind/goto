# goto
long distance directory jumper


in you bashrc:

function gt()  {
    perl6 ~/../../goto/goto.pl6 "$@"
    cd $(cat ~/../../goto/last_choice)
}
