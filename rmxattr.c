// on macOS, there's an "xattr" command line app, written in Python, and
//  it's hella slow to do this to remove the Apple quarantine flag...
//
//   find . -exec xattr -d com.apple.quarantine {} \;
//
// ...since you end up loading and unloading the Python interpreter for every
//  file and directory.
//
// So this is a simple C app to walk a directory tree, blowing away a specific
//  extended attribute. This takes a fraction of a second where the "find"
//  command above can take tens of minutes.
//
// This code is public domain. Use however you like.  --ryan.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/xattr.h>
#include <sys/stat.h>
#include <errno.h>

static int walktree(const char *xattr, const char *tree)
{
    int retval = 0;
    struct stat statbuf;
    if (stat(tree, &statbuf) == -1) {
        fprintf(stderr, "Couldn't stat '%s': %s\n", tree, strerror(errno));
        return -1;
    }

    if (S_ISDIR(statbuf.st_mode)) {
        const size_t treelen = strlen(tree);
        DIR *dirp = opendir(tree);
        struct dirent *dent;
        if (dirp == NULL) {
            fprintf(stderr, "Couldn't opendir '%s': %s\n", tree, strerror(errno));
            retval = -1;
        } else {
            while ((dent = readdir(dirp)) != NULL) {
                const char *name = dent->d_name;
                if ( (strcmp(name, ".") != 0) && (strcmp(name, "..") != 0)) {
                    const size_t childlen = treelen + strlen(name) + 2;
                    char *child = (char *) malloc(childlen);
                    if (child == NULL) {
                        fprintf(stderr, "Out of memory!\n");
                        exit(-1);
                    }
                    snprintf(child, childlen, "%s/%s", tree, name);
                    if (walktree(xattr, child) == -1) {
                        retval = -1;
                    }
                    free(child);
                }
            }
            closedir(dirp);
        }
    }

    #ifdef __linux__
    if (lremovexattr(tree, xattr) == -1)
    #else
    if (removexattr(tree, xattr, XATTR_NOFOLLOW) == -1)
    #endif
    {
        if (errno != ENOATTR) {
            fprintf(stderr, "Couldn't remove attribute '%s' from '%s': %s\n", xattr, tree, strerror(errno));
            retval = -1;
        }
    }

    return retval;
}

int main(int argc, char **argv)
{
    const char *xattr = argv[1];
    int retval = 0;
    int i;

    if (argc < 3) {
        fprintf(stderr,
            "\n"
            "USAGE: %s <xattrname> <path1> ... <pathN>\n"
            "\n"
            "    Paths can be files, or directories that will be walked.\n"
            "\n", argv[0]);
        return 2;
    }

    for (i = 2; i < argc; i++) {
        if (walktree(xattr, argv[i]) < 0) {
            retval = 1;
        }
    }

    return retval;
}

// end of rmxattr.c ...
