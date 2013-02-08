package Bc125At::GUI;

use strict;
use warnings;

use Bc125At::Command;

BEGIN {
    eval {
        require Gtk2;
        Gtk2->init;
    };
    if ($@) {
        die "Gtk2 is not available. Please install Gtk2-perl in order to use the GUI.\n";
    }
}

sub new {
    my ($package, $scanner) = @_;
    my $window = Gtk2::Window->new('toplevel');
    my $self   = {
        window  => $window,
        scanner => $scanner
    };
    bless $self;
    $self->_setup_widgets();
    return $self;
}

sub main {
    my $self = shift;
    $self->{window}->show_all();
    Gtk2->main;
}

sub _setup_widgets {
    my $self = shift;

    my $window = $self->{window};

    my $scroll = Gtk2::ScrolledWindow->new(Gtk2::Adjustment->new(400, 200, 800, 1, 1, 50));

    my $vbox = Gtk2::VBox->new(0);
    my $hbox = Gtk2::HBox->new();

    for (
        _button(
            "Read from scanner",
            sub {
                $self->{scanner}->begin_program;
                $self->populate_table($self->{scanner}->get_all_channel_info());
                $self->{scanner}->end_program;
            }
        ),
        _button(
            "Write to scanner",
            sub {
                $self->{scanner}->begin_program;
                $self->{scanner}->write_channels(undef, $self->harvest_table());
                $self->{scanner}->end_program;
            }
        ),
        _button(
            "Load file...",
            sub {
                my $filename = $self->_load_dialog() || return;
                my $info = Bc125At::Command::undumper($filename) || die;
                $self->populate_table($info);
                print "Loaded channels from $filename\n";
            }
        ),
        _button(
            "Save file...",
            sub {
                my $filename = $self->_save_dialog() || return;
                my $info = $self->harvest_table();
                Bc125At::Command::dumper($filename, $info, 'channel');
                print "Saved channels to $filename\n";
            }
        )
      )
    {
        $hbox->add($_);
    }

    $vbox->add($hbox);

    my $table = Gtk2::Table->new(501, 8, 1);

    $scroll->add_with_viewport($table);

    $scroll->set_size_request(720, 600);

    my @head = qw(name frq mod ctcss_dcs dly lout pri);

    my @entries;

    for my $row (-1 .. 499) {
        if ($row >= 0) {
            my $label = Gtk2::Label->new($row + 1);
            $table->attach_defaults($label, 0, 1, 1 + $row, 2 + $row);
        }
        for my $col (0 .. 6) {

            my $widget;

            if ($row == -1) {
                $widget = Gtk2::Label->new($head[$col]);
            }
            else {
                $entries[$row][$col] = $widget = Gtk2::Entry->new();
            }
            $widget->set_size_request(50, 25);

            my $width = $col == 0 ? 2 : 1;
            my $hoff  = $col == 0 ? 0 : 1;
            $table->attach_defaults($widget, $hoff + 1 + $col, $hoff + $width + 1 + $col, 1 + $row, 2 + $row);
        }
    }

    $vbox->add($scroll);
    $window->add($vbox);

    $self->{entries} = \@entries;
}

sub _button {
    my ($text, $sub) = @_;
    my $button = Gtk2::Button->new($text);
    $button->signal_connect(clicked => $sub);
    return $button;
}

sub populate_table {
    my ($self, $info) = @_;
    for my $row (0 .. $#$info) {
        _populate_row($self->{entries}[$row] || die, $info->[$row]);
    }
}

sub _populate_row {
    my ($row_widgets, $rowinfo) = @_;
    my @ri = @$rowinfo{qw(name frq mod ctcss_dcs dly lout pri)};
    for my $col (0 .. $#ri) {
        $row_widgets->[$col]->set_text($ri[$col]);
    }
}

sub harvest_table {
    my $self = shift;
    my @info;
    for my $row (0 .. 499) {
        $info[$row] = _harvest_row($self->{entries}[$row] || die, $row);
    }
    return \@info;
}

sub _harvest_row {
    my ($row_widgets, $row_n) = @_;
    my @ri;
    for my $col (0 .. 6) {
        $ri[$col] = $row_widgets->[$col]->get_text();
    }
    unshift @ri, 'CIN', $row_n + 1;
    my $rowinfo = {};
    @$rowinfo{qw(cmd index name frq mod ctcss_dcs dly lout pri)} = @ri;
    return $rowinfo;
}

sub _load_dialog {
    my $self = shift;
    no strict;
    my $open = Gtk2::FileChooserDialog->new("Load channels", $self->{window}, GTK_FILE_CHOOSER_ACTION_OPEN, 'Cancel', GTK_RESPONSE_CANCEL, 'Open', GTK_RESPONSE_ACCEPT);
    $open->show;
    my $resp = $open->run;
    $open->hide;
    return $open->get_filename if $resp =~ /accept/i;
    return;
}

sub _save_dialog {
    my $self = shift;
    no strict;
    my $save = Gtk2::FileChooserDialog->new("Save channels", $self->{window}, GTK_FILE_CHOOSER_ACTION_SAVE, 'Cancel', GTK_RESPONSE_CANCEL, 'Save', GTK_RESPONSE_ACCEPT);
    $save->show;
    my $resp = $save->run;
    $save->hide;
    return $save->get_filename if $resp =~ /accept/i;
    return;
}

1;