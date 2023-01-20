package Point;
use Moose;
#
has 'x' => (is=>'rw', isa=>'Num');
has 'y' => (is=>'rw', isa=>'Num');

=pod old way without Moose
sub new {
    my $class=shift;
    my $self={
        x=>shift,
        y=>shift
    };
    $self=bless($self,$class);
    return $self;
}
=cut

sub toString{
    my $self=shift;
    my $st="";
    $st.="x:$self->{x}";  
    $st.="y:$self->{y}";
    $st="($self->{x},$self->{y})";
    return $st;
}
1