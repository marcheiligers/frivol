<!--- TODO: Date and version -->
# March 2014 (v)
<!--- TODO: Check on this version number -->
- Drop support for Redis < 2.2.6
- Add backends for Redis, Redis::Distributed and Riak
- FIXED: counters never expire if created with increment or decrement methods

# Previous
<!--- TODO: Fill in -->


# TODO/BUGS(?):
- Hook AR reload method to clear_storage?
- Add a way (maybe using MR) to expire keys in Riak
- BUG: Now, counters always have their expiry reset
