/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
int string_buf_idx;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
Boolean seenNull;
int commentDepth;

%}

/*
 * Define names for regular expressions here.
 */

%x COMMENT
%x STRING

%%

 /*
  * Nested comments.
  */

"(*" {
  commentDepth = 1;
  BEGIN(COMMENT);
}

<COMMENT>{
    /* Start of nested comment. */
  "(*" {
    commentDepth += 1;
  }

    /* End of comment. */
  "*)" {
    commentDepth -= 1;
    if (commentDepth == 0) {
      BEGIN(INITIAL);
    }
  }

    /* Newline. */
  \n {
    curr_lineno += 1;
  }

    /* Unexpected EOF. */
  <<EOF>> {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return (ERROR);
  }

  "*" {}
  "(" {}
  [^\n*(]+ {}
}

"*)" {
  cool_yylval.error_msg = "Unmatched *)";
  return (ERROR);
}

 /*
  * Single-line comments.
  */

--[^\n]* {}

 /*
  *  The single-character tokens.
  */

"{" {
  return (int)'{';
}

"}" {
  return (int)'}';
}

"(" {
  return (int)'(';
}

")" {
  return (int)')';
}

":" {
  return (int)':';
}

"@" {
  return (int)'@';
}

"." {
  return (int)'.';
}

";" {
  return (int)';';
}

"," {
  return (int)',';
}

"+" {
  return (int)'+';
}

"-" {
  return (int)'-';
}

"*" {
  return (int)'*';
}

"/" {
  return (int)'/';
}

"~" {
  return (int)'~';
}

"<" {
  return (int)'<';
}

"=" {
  return (int)'=';
}

 /*
  *  The multiple-character operators.
  */

"=>" {
 return (DARROW);
}

"<-" {
  return (ASSIGN);
}

"<=" {
  return (LE);
}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

[cC][lL][aA][sS][sS] {
  return (CLASS);
}

[eE][lL][sS][eE] {
  return (ELSE);
}

[fF][iI] {
  return (FI);
}

[iI][fF] {
  return (IF);
}

[iI][nN] {
  return (IN);
}

[iI][nN][hH][eE][rR][iI][tT][sS] {
  return (INHERITS);
}

[lL][eE][tT] {
  return (LET);
}

[lL][oO][oO][pP] {
  return (LOOP);
}

[pP][oO][oO][lL] {
  return (POOL);
}

[tT][hH][eE][nN] {
  return (THEN);
}

[wW][hH][iI][lL][eE] {
  return (WHILE);
}

[cC][aA][sS][eE] {
  return (CASE);
}

[eE][sS][aA][cC] {
  return (ESAC);
}

[oO][fF] {
  return (OF);
}

[nN][eE][wW] {
  return (NEW);
}

[iI][sS][vV][oO][iI][dD] {
  return (ISVOID);
}

[nN][oO][tT] {
  return (NOT);
}

t[rR][uU][eE] {
  cool_yylval.boolean = true;
  return (BOOL_CONST);
}

f[aA][lL][sS][eE] {
  cool_yylval.boolean = false;
  return (BOOL_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */

\" {
  string_buf_idx = 0;
  seenNull = false;
  BEGIN(STRING);
}

<STRING>{
    /* End of string. */
  \" {
    BEGIN(INITIAL);

    /* String too long. */
    if (string_buf_idx == MAX_STR_CONST) {
      cool_yylval.error_msg = "String constant too long";
      return (ERROR);
    }

    /* Null character encountered. */
    else if (seenNull) {
      cool_yylval.error_msg = "String contains null character";
      return (ERROR);
    }

    string_buf[string_buf_idx] = '\0';

    cool_yylval.symbol = stringtable.add_string(string_buf);
    return (STR_CONST);
  }

    /* Unexpected newline. */
  \n {
    curr_lineno += 1;
    BEGIN(INITIAL);

    /* String too long. */
    if (string_buf_idx == MAX_STR_CONST) {
      cool_yylval.error_msg = "String constant too long";
    }

    /* Null character encountered. */
    else if (seenNull) {
      cool_yylval.error_msg = "String contains null character";
    }

    /* No earlier errors. */
    else {
      cool_yylval.error_msg = "Unterminated string constant";
    }

    return (ERROR);
  }

    /* Unexpected EOF. */
    <<EOF>> {
      BEGIN(INITIAL);
      cool_yylval.error_msg = "EOF in string constant";
      return (ERROR);
    }

    /*
    * Strings are enclosed in double quotes "...". Within a string, a sequence
    * ‘\c’ denotes the character ‘c’, with the exception of the following:
    *  \b backspace
    *  \t tab
    *  \n newline
    *  \f formfeed
    */

  \\n {
    string_buf[string_buf_idx++] = '\n';
  }

  \\t {
    string_buf[string_buf_idx++] = '\t';
  }

  \\b {
    string_buf[string_buf_idx++] = '\b';
  }

  \\f {
    string_buf[string_buf_idx++] = '\f';
  }

  \\[^\0] {
    if (yytext[1] == '\n') {
      curr_lineno += 1;
    }
    string_buf[string_buf_idx++] = yytext[1];
  }

  \\ {}

  \0 {
    seenNull = true;
  }

  [^\\\n\"\0]+ {
    int yidx = 0;

    while (yytext[yidx]) {
      /* Note that this loop is allowed to go too far, such that
       * string_buf_idx == MAX_STR_CONST by the end of the loop, leaving no room
       * for a null terminator to be added to string_buf, in order to indicate
       * to the end-of-string rules above (double-quote and newline) that the
       * string literal was too long.
       */
      if (string_buf_idx < MAX_STR_CONST) {
        string_buf[string_buf_idx] = yytext[yidx];
        string_buf_idx += 1;
        yidx += 1;
      }
    }
  }
}

 /*
  * Integer constants.
  */

[0-9]+ {
  cool_yylval.symbol = inttable.add_string(yytext);
  return (INT_CONST);
}

 /*
  * Whitespace.
  */

[ \f\r\t\v] {}

\n {
  curr_lineno += 1;
}

 /*
  * Identifiers.
  */

[a-z][a-zA-Z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}

[A-Z][a-zA-Z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

 /*
  *  Catch everything else as an error.
  */

[^a]|a {
  cool_yylval.error_msg = yytext;
  return (ERROR);
}

%%
