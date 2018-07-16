# wFilesFilterCaching [![Build Status](https://travis-ci.org/Wandalen/wFilesFilterCaching.svg?branch=master)](https://travis-ci.org/Wandalen/wFilesFilterCaching)


Filter that works same like original provider, but additionally updates it own file stats, names and [record]( https://github.com/Wandalen/wFiles/blob/master/wFileRecord.md ) caches. Each cache is a map with file path as a key and cached data as value. Also filter can use file watcher to update cache on changes made by other processes. To perform behavior of original provider filter wraps its methods.

### Installation
```npm install wfilesfiltercaching ```

### Usage

#### Options
* original  { object }[ optional, default : default provider on target platform ] - provider to wrap.
* cachingDirs  { boolean }[ optional, default : 1 ] - enables updates of files list cache;
* cachingStats { boolean }[ optional, default : 1 ] - enables updates of file stats cache;
* cachingRecord { boolean }[ optional, default : 1 ] - enables updates of file record cache;
* updateOnRead { boolean }[ optional, default : 0 ] - update each cache after file read operation;
* watchPath { string }[ optional, default : null ] -  path for file watcher, if specified file watcher will start;
* watchOptions { object }[ optional, default : {} ] - file watcher options.

Please visit [ wFiles ]( https://github.com/Wandalen/wFiles ) for information about providers.

###### Example
```javascript
var caching = _.FileFilter.Caching();

/* make file operation like real provider*/

var filePath = 'path/to/file';
var stats = cachingStats.fileStat( filePath );
console.log( stats );

/* get file stats cache */
console.log( "Stats: ", caching._cacheStats );

```











