#include <stdio.h>
#include <stdlib.h>
#include "util.h"
#include "errormsg.h"

extern int yyparse(void);
void parse(string fname) 
{
 EM_reset(fname);
 if (yyparse() == 0) /* parsing worked */
	fprintf(stderr,"Parsing successful!\n");
 else {printf("FAIL!\n");}
}

int main(int argc, char **argv) {
 string fname; 
 int tok;
 if (argc!=2) {printf("usage: a.out filename\n"); exit(1);}
  
 parse(argv[1]);
 
 return 0;
}

