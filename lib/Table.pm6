use v6.c;

unit class Table;

has @!rows;
has @.keys;

###############################################################################

method add-row(%row, Int :$pos = @!rows.elems) {
    for @!keys -> $key {
        fail "table row is missing value in column $key" unless %row{$key}:exists;
    }
    fail "table row is must not have a column ''pos''" if %row<pos>:exists;
    fail "position $pos does not exist" unless @!rows[$pos]:exists or $pos == @!rows.elems;
    @!rows.splice($pos, 0, %row );
}

multi method move-row( Int :$from! where { @!rows[$from]:exists },
                       Int :$to! where { @!rows[$to]:exists }    ) {
    @!rows.splice($to, 0, @!rows.splice($from, 1));
}
multi method move-row( Pair :$where!, Int :$to! where { @!rows[$to]:exists }) {
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    $.get-row-pos(where => $where).reverse.map: {$.move-row(from => $_, to => $to)};
}

multi method remove-row(Int $pos where { @!rows[$pos]:exists }) {@!rows.splice($pos, 1)}
multi method remove-row( Pair :$where!) {
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    $.get-row-pos(where => $where).reverse.map:  {$.remove-row($_)};
}

multi method get-row(Int $pos where { @!rows[$pos]:exists }) { @!rows[$pos] }
multi method get-row( Pair :$where! --> List) {
    return $.get-row($where.value) if $where.key eq 'pos';
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    (gather {@!rows.map:{take $_ if $_.{$where.key} ~~ $where.value}}).list
}

method get-row-pos( Pair :$where! --> List) {
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    (gather {@!rows.pairs.map:{take $_.key if $_.value.{$where.key} ~~ $where.value}}).list
}

method get-column(Str $key){
    fail "'$key' is not a registered table column key" unless $key (elem) @.keys.Set;
    (@!rows.pairs.map:{$_.key => $_.value.{$key}}).Hash;
}

###############################################################################

multi method get-value(Pair :$where!, Str :$column! --> List){
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    return ($.get-row-pos(where => $where)).list if $column eq 'pos';
    fail " \"$column\" is not a registered table column key"      unless $column (elem) @.keys;
    ($.get-row(where => $where).map:  {$_{$column}}).list;
}

multi method set-value(Pair :$where!, Pair :$to!){
    fail " \"{$where.key}\" is not a registered table column key" unless $where.key (elem) @.keys;
    fail " \"{$to.key}\" is not a registered table column key" unless $to.key (elem) @.keys;
    return ($.get-row-pos(where => $where)).reverse.map: {$.move-row(from => $_, to => $to.value)} if $to.key eq 'pos';
    ($.get-row(where => $where).map:  {$_{$to.key} = $to.value});
}

###############################################################################

method content(Str :$sorted-by = 'pos', :@columns = @.keys, Bool :$show-pos = False --> List) {
    my $sorted-rows = ($show-pos or 'pos' (elem) @columns)
                    ?? @!rows.pairs.map: {$_.value.append: (:pos($_.key))}
                    !! @!rows;
    for @columns -> $key {
        fail " \"$key\" is not a registered table column key" unless $key (elem) @.keys;
    }
    if $sorted-by ne 'pos' {
        fail " \"$sorted-by\" is not a registered table column key" unless $sorted-by (elem) @.keys;
        $sorted-rows = $sorted-rows.sort: {$^a{$sorted-by} leg $^b{$sorted-by}};
    }
    my $columns = ($show-pos and not 'pos' (elem) @columns) ?? ('pos', @columns).flat !! @columns; 
    (gather { for $sorted-rows.list -> $row {
            take ($row.map: { $columns.cache.map:{ $_ => $row{$_} } }).flat.Hash;
    } }).list
}

###############################################################################