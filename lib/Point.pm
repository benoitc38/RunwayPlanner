=pod
Point representation
=cut
package Point;
use Moose;

has 'x' => (is=>'rw', isa=>'Num');
has 'y' => (is=>'rw', isa=>'Num');

# 
sub CreateFromString{
    my $cls=shift;
    my @coordinates=split(' ',shift);
    if (scalar @coordinates>=2){
        return Point->new(x=>$coordinates[0],y=>$coordinates[1]);
    }
    return undef;
}

sub toString{
    my $self=shift;
    my $st="";
    $st.="x:$self->{x}";  
    $st.="y:$self->{y}";
    $st="($self->{x},$self->{y})";
    return $st;
}
1