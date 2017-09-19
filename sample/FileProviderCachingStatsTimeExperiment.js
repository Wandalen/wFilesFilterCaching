
if( typeof module !== 'undefined' )
require( 'wfilesfiltercaching' )

var _ = wTools;

var provider = _.fileProvider;
var filter = _.FileFilter.Caching();

var timeSingle = _.timeNow();
provider.fileStat({ filePath : __filename });
timeSingle = _.timeNow() - timeSingle;

var time = _.timeNow();
for( var i = 0; i < 10000; ++i )
{
  filter.fileStat( { filePath : __filename } )
}

console.log( _.timeSpent( 'Spent to make filter.fileStat 10k times, using native path',time-timeSingle ) );
