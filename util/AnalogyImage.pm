use 5.010;
use MooseX::Declare;
use MooseX::AttributeHelpers;
use Config::Std;

use version; our $VERSION = qv('0.01');

class AnalogyArrow {
    has 'left_attribute' => (
        is       => 'ro',
        isa      => 'Any',
        required => 1,
    );
    has 'right_attribute' => (
        is       => 'ro',
        isa      => 'Any',
        required => 1,
    );
    has 'label' => (
        is       => 'ro',
        isa      => 'Any',
        required => 1,
    );

};
class AnalogyImage {
    has 'attributes' => (
        metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ArrayRef[Str]',
        default   => sub { [] },
        provides  => { push => 'push_attribute', }
    );

    has 'left_category' => (
        is       => 'rw',
        isa      => 'Str',
        required => 0,
    );

    has 'right_category' => (
        is       => 'rw',
        isa      => 'Str',
        required => 0,
    );

    has 'arrows' => (
        metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ArrayRef[AnalogyArrow]',
        default   => sub { [] },
        provides  => { push => 'push_arrow' }
    );

    method load_from_file($filename) {
        use Config::Std;
          read_config $filename => my %config;

          $self->left_category( $config{''}{left_category} );
          $self->right_category( $config{''}{right_category} );

          for ( @{ $config{''}{attributes} } ) {
            $self->push_attribute($_);
        }

        my $arrow_count = $config{''}{arrow_count};
          for ( 1 .. $arrow_count ) {
            my $arrow = AnalogyArrow->new( $config{ 'arrow_' . $_ } );
            $self->push_arrow($arrow);
        }
    };

    method find_index_of_attribute( Str $attribute_name) {
        my $i = 0;
          for ( @{ $self->attributes() } ) {
            return $i if $attribute_name eq $_;
            $i++;
        }
        die "Unknown attribute '$attribute_name'";
    };

    method calculate_arrow_positions( AnalogyArrow $arrow) {
        return (
            $self->find_index_of_attribute( $arrow->left_attribute() ),
            $self->find_index_of_attribute( $arrow->right_attribute() )
        );
    };

    method draw( $canvas, Num $height) {
        my $attribute_count   = scalar( @{ $self->{attributes} } );
          my $y_margin        = 20;
          my $y_per_attribute = ( $height - 2 * $y_margin ) / $attribute_count;
          $self->draw_labels( $canvas, $y_margin, $y_per_attribute );
          $self->draw_arrows( $canvas, $y_margin, $y_per_attribute );
    };

    method draw_labels( $canvas, Num $y_margin, Num $y_per_attribute) {
        my $index = 0;
          for my $attribute_name ( @{ $self->attributes } ) {
            my $y = $y_margin + ( $index + 0.5 ) * $y_per_attribute;
            $canvas->createText(
                120, $y,
                -text   => $attribute_name,
                -anchor => 'e',
                -font => 'Lucida 10',
            );
            $canvas->createText(
                380, $y,
                -text   => $attribute_name,
                -anchor => 'w',
                -font => 'Lucida 10',
            );

            $index++;
        }
      }

      method draw_arrows( $canvas, Num $y_margin, Num $y_per_attribute) {
        for my $arrow ( @{ $self->arrows } ){
            my ( $y1, $y2 ) =
              map { $y_margin + ( $_ + 0.5 ) * $y_per_attribute }
              $self->calculate_arrow_positions($arrow);
              $canvas->createLine( 160, $y1, 320, $y2, -arrow => 'last' );
              my ( $label_x, $label_y, $label_anchor );
              if ( $y1 == $y2 ) {
                $label_x      = 240;
                $label_anchor = 's';
                $label_y      = $y1 - 2;
            }
            elsif ( $y1 < $y2 ) {    # sloping down
                $label_x      = 240 + 2;
                $label_y      = -2 + ( $y1 + $y2 ) / 2;
                $label_anchor = 'sw';
            }
            else {
                $label_x      = 240 - 2;
                $label_y      = -2 + ( $y1 + $y2 ) / 2;
                $label_anchor = 'se';
            }
            $canvas->createText(
                $label_x, $label_y,
                -text   => $arrow->label,
                -anchor => $label_anchor,
                -font => 'Lucida 8',
            );
          }
      };
};

1;
