#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

int
main(int ac, char **av)
{
  int minlen = 10;
  int badcut = 3*1;	// 3 chars of badness 1, or similar

  if (!av[1])
    {
      fprintf(stderr, "Usage: %s file\n", av[0]);
      exit(1);
    }
  FILE *fp = strcmp(av[1], "-") ? fopen(av[1], "r") : stdin;
  if (!fp)
    {
      fprintf(stderr, "%s: %s\n", av[1], strerror(errno));
      exit(1);
    }
  
  int ch;
  int badcount = 0;
  int printing = 0;
  int queuelen = 0;
  int nulseen = 0;
  char queuebuf[20];

  while ((ch = getc(fp)) != EOF)
    {
      int badness = 0;

      if (ch == 0)
        { 
	  nulseen++;	// a nul every second char is just fine.
	  if (nulseen > 1) badness = badcut+1;
	}
      else
        {
	  nulseen = 0;
	  if (ch > 127)				badness = 1;	// latin1 or utf8 byte
          else if (ch < 32 && ch != '\t' && 
	           ch != '\n' && ch != '\r') 	badness = badcut+1;	// control char.
          else /* (good char) */		badness = 0;
	}

      badcount += badness;

      if (!printing && !badness)
        {
	  queuebuf[queuelen] = ch;
	  if (ch) queuelen++;	// always skip \0 bytes
	  if (queuelen >= minlen) 
	    {
	      int j;
	      for (j = 0; j < queuelen; j++) 
	        putchar(queuebuf[j]);
	      queuelen = 0;
	      printing = 1;
	    }
	  continue;
	}

      if (printing)
        {
	  if (!badness && ch)
	    {
	      if (queuelen)
	        {
	          int j;
	          for (j = 0; j < queuelen; j++) 
	            putchar(queuebuf[j]);
	          queuelen = 0;
		}
	      queuelen = 0;
	      badcount = 0;
	      putchar(ch);
	    }
	  else
	    {
	      queuebuf[queuelen] = ch;
	      if (ch) queuelen++;	// always skip \0 bytes
	      if (badcount >= badcut) 
	        { 
		  queuelen = 0;
	          printing = 0;
		  badcount = 0;
		  putchar('\f');	// next string.
		  putchar('\n');	// next string.
		}
	    }
	}
    }
  fclose(fp);
  return 0;
}
