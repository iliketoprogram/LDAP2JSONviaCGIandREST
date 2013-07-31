package LDAP2JSONviaCGIandREST;
{
	use Dancer ':syntax';
	use Net::LDAP;
	use Data::Dumper;
	use strict;
	use warnings;
	our $VERSION = '0.1';

	get '/' => sub {
		template 'index';
	};

	get '/search/:searchString' => sub {
		content_type 'application/json';
		my @sr = &getSearchResults( param('searchString') );
		return to_json( \@sr );
	};

	sub getSearchResults {
		my ($searchString) = @_;
		my $userName       = &discoverUsername();
		my $userGroups     = &discoverUserGroups();
		my $searchLevel =
		  &discoverSearchLevelByUserAndGroups( $userName, $userGroups );
		my $ldap = &discoverLDAP('ldap.mtu.edu');
		my @results = &performSearch( $searchString, $searchLevel, $ldap );
		return @results;
	}

	sub discoverLDAP {
		my ($host) = @_;
		my $ldap = Net::LDAP->new($host) or die "$@";
		return $ldap;
	}

	sub discoverSearchLevelByUserAndGroups {
		my ( $userName, $userGroups ) = @_;
		my $searchLevel = 0;
		if ( $userName ne 'anon' ) {
			if ( $userName eq 'scott' ) {
				$searchLevel = 10;
			}
			else {
				$searchLevel = 5;
			}
		}
		return $searchLevel;
	}

	sub performSearch {
		my ( $searchString, $searchLevel, $ldap ) = @_;

		my @results = &simpleLDAPsearch( $ldap, $searchString );
		if ( !scalar(@results) ) {
			push( @results,
				    "Hello, thank you for searching at level $searchLevel for ["
				  . $searchString
				  . "].  No results were found." );
		}
		return @results;
	}

	sub discoverUsername {
		return "anon";
	}

	sub discoverUserGroups {
		my @results = ();

		return join( ',', @results );
	}

	sub filteredLDAPsearch {
		my ( $ldap, $searchString, $attrs, $base ) = @_;

		my @Attrs = ();    # request all available attributes
		                   # to be returned.

		my $result = &LDAPsearch( $ldap, "sn=*", \@Attrs, $base );
	}

	sub simpleLDAPsearch {
		my ( $ldap, $searchString ) = @_;
		return &LDAPsearch( $ldap, $searchString, (), '' );

	}

	sub LDAPsearch {
		my ( $ldap, $searchString, $attrs, $base ) = @_;

		# if they don't pass a base... set it for them

		if ( !$base ) { $base = "o=mycompany, c=mycountry"; }

		# if they don't pass an array of attributes...
		# set up something for them

		if ( !$attrs ) { $attrs = [ 'cn', 'mail' ]; }

		my $result = $ldap->search(
			base   => "$base",
			scope  => "sub",
			filter => "$searchString",
			attrs  => $attrs
		);

		my @entries = $result->entries;
		my @results = ();
		foreach my $entr (@entries) {
			my $attr;
			foreach $attr ( sort $entr->attributes ) {
				next if ( $attr =~ /;binary$/ );
				push( @results,
					$entr->dn . " :: $attr : " . $entr->get_value($attr) );
			}

		}
		return @results;
	}

	1;
}
