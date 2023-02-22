@load base/frameworks/notice

@load frameworks/files/hash-all-files

@load ./virus-total.zeek

module VirusTotal;

export {
	redef enum Notice::Type += {
		Match
	};

	## Number of positive AV hits to do the Match notice.
	const hits_to_notice = 0 &redef;

	# We want to check virustotal for files of the following types.
	const match_file_types = /application\/x-dosexec/ | 
	                         /application\/x-executable/ | /text\/plain/ | 	
							 /application\/zip/ | /text\/x-python/ &redef;

}

event file_hash(f: fa_file, kind: string, hash: string)
	{
	if ( kind == "sha1" && f$info?$mime_type &&
	     match_file_types in f$info$mime_type )
		{
		when [copy f, copy hash]( local info = VirusTotal::scan_hash(f, hash) )
			{
			if ( |info$hits| < hits_to_notice )
				break;

			local downloader: addr = 0.0.0.0;
			# for ( host in f$info$rx_hosts )
			# 	{
			# 	# Pick a receiver host to use here (typically only one anyway)
			# 	downloader = host;
			# 	}

			NOTICE([$note=VirusTotal::Match,
			        $msg=fmt("VirusTotal match on %d AV engines hit by %s", |info$hits|, downloader),
			        $sub=info$permalink,
			        $n=|info$hits|,
			        $src=downloader]);
			}
		}
	}
