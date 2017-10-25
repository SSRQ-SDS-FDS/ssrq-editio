'use strict';

var gulp =                  require('gulp'),
    less =                  require('gulp-less'),
    sourcemaps =            require('gulp-sourcemaps'),
    LessAutoprefix =        require('less-plugin-autoprefix'),
    autoprefix =            new LessAutoprefix({ browsers: ['last 2 versions'] }),
    LessPluginCleanCSS =    require('less-plugin-clean-css'),
    cleanCSSPlugin =        new LessPluginCleanCSS({advanced: true}),

    input = {
        'styles':               'resources/css/style.less'
    },
    output  = {
        'styles':               'resources/css'
    };

// ****************  Styles ****************** //

gulp.task('build:styles', function(){
    return gulp.src(input.styles)
        .pipe(sourcemaps.init())
        .pipe(less({ plugins: [cleanCSSPlugin, autoprefix] }))
        .pipe(sourcemaps.write())
        .pipe(gulp.dest(output.styles))
});

// Default task (which is called by 'npm gulp' task)
gulp.task('default', ['build:styles']);
