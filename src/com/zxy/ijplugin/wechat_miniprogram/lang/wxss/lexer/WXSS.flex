package com.zxy.ijplugin.wechat_miniprogram.lang.wxss.lexer;

import com.intellij.psi.TokenType;
import com.intellij.psi.tree.IElementType;
import com.zxy.ijplugin.wechat_miniprogram.lang.wxss.psi.WXSSTypes;

%%

%{
    private int beforeCommentState = YYINITIAL;

    private void saveBeforeCommentState(){
        this.beforeCommentState = yystate();
    }

    private int beforeStringState = YYINITIAL;

    private void saveBeforeStringState(){
        this.beforeStringState = yystate();
    }
%}

%unicode

%class _WXSSLexer
%public
%implements com.intellij.lexer.FlexLexer
%function advance
%type IElementType

// state
%state IDENTIFIER
%state PERIOD
%state SELECTOR_GROUP
%state ID_SELECTOR
%state CLASS_SELECTOR
%state STYLE_SELCTION
%state ATTRIBUTE_START
%state ATTRIBUTE_VALUE_STRAT
%state ATTRIBUTE_VALUE
%state ATTRIBUTE_VALUE_END
%state ATTRIBUTE_VALUE_NUMBER
%state ATTRIBUTE_VALUE_STRING_START_DQ
%state ATTRIBUTE_VALUE_STRING_START_SQ
%state ATTRIBUTE_VALUE_FUNCTION
%state ATTRIBUTE_VALUE_FUNCTION_ARGS
%state ATTRIBUTE_VALUE_FUNCTION_ARG_NUMBER
%state COMMENT
%state STRING_START_DQ
%state STRING_START_SQ

ALPHA=[:letter:]
CRLF=\R
WHITE_SPACE=[\ \n\t\f]
WHITE_SPACE_AND_CRLF =     ({CRLF}|{WHITE_SPACE})+
DIGIT=[0-9]

IDENTIFIER_START = {ALPHA}|"-"|"_"
IDENTIFIER = {IDENTIFIER_START}({IDENTIFIER_START}|{DIGIT})*

ATTRIBUTE_VALUE_LITERAL = {ALPHA}({ALPHA}|"-"|"_"|{DIGIT})*

ATTRIBUTE_NAME = {ALPHA}({ALPHA}|-)*
WHITE_SPACE_AND_CRLF =     ({CRLF}|{WHITE_SPACE})+
HASH = #([0-9a-fA-F]{3}|[0-9a-fA-F]{6})
NUMBER = {DIGIT}*\.{DIGIT}+ | {DIGIT}+(\.{DIGIT}+)?
NUMBER_UNIT = {ALPHA}+ | %
NUMBER_WITH_UNIT = {NUMBER}{NUMBER_UNIT}
FUNCTION_NAME = {IDENTIFIER}
ELEMENT_NAME = ({ALPHA}|-)+
COMMENT_START = "/*"
COMMENT_END = "*/"
UNICODE_RANGE = "U+"([0-9a-fA-F]{1,4}(-[0-9a-fA-F]{1,4})?|[0-9a-fA-F?]{1,4})
%%

<YYINITIAL> {
    "@import" {
        return WXSSTypes.IMPORT_KEYWORD;
    }
    ";" {
          return WXSSTypes.SEMICOLON;
    }

}

// 选择器
<YYINITIAL> "#"|"."|{ELEMENT_NAME} {
    yypushback(yylength());
    yybegin(SELECTOR_GROUP);
}

<SELECTOR_GROUP> {
    {ELEMENT_NAME} {
          return WXSSTypes.ELEMENT_NAME;
      }
    "#" {
          yybegin(ID_SELECTOR);
        return WXSSTypes.NUMBER_SIGN;
    }
    "." {
          yybegin(CLASS_SELECTOR);
          return WXSSTypes.DOT;
      }
    (":"|"::")("before"|"after") {
          return WXSSTypes.PSEUDO_SELECTOR;
      }
      {WHITE_SPACE_AND_CRLF} {
                        return TokenType.WHITE_SPACE;
                    }
}

<CLASS_SELECTOR> {IDENTIFIER} {
           yybegin(SELECTOR_GROUP);
                  return WXSSTypes.CLASS;
      }

<ID_SELECTOR> {
    {IDENTIFIER} {
          yybegin(SELECTOR_GROUP);
        return WXSSTypes.ID;
      }
}

<ID_SELECTOR,CLASS_SELECTOR,SELECTOR_GROUP>{
    "," {
        yybegin(SELECTOR_GROUP);
        return WXSSTypes.COMMA;
    }
    {WHITE_SPACE} {
        yybegin(SELECTOR_GROUP);
        return TokenType.WHITE_SPACE;
    }
    "{" {
        yybegin(STYLE_SELCTION);
        yypushback(yylength());
    }
}

<STYLE_SELCTION>{
    "{" {
        return WXSSTypes.LEFT_BRACKET;
    }
    {WHITE_SPACE_AND_CRLF} {
          return TokenType.WHITE_SPACE;
      }
    {ATTRIBUTE_NAME} {
          yybegin(ATTRIBUTE_START);
        return WXSSTypes.ATTRIBUTE_NAME;
      }
    "}" {
          yybegin(YYINITIAL);
        return WXSSTypes.RIGHT_BRACKET;
      }
}

<ATTRIBUTE_START>{
    ":" {
          yybegin(ATTRIBUTE_VALUE_STRAT);
          return WXSSTypes.COLON;
      }

      {WHITE_SPACE_AND_CRLF} {
            return TokenType.WHITE_SPACE;
        }
}

<ATTRIBUTE_VALUE_STRAT>{

      [^\R\ \n\t\f,;}]+ {
          yypushback(yylength());
          yybegin(ATTRIBUTE_VALUE);
      }
            "," {
                yybegin(ATTRIBUTE_VALUE_STRAT);
                return WXSSTypes.COMMA;
            }
       ";" {
            yybegin(STYLE_SELCTION);
            return WXSSTypes.SEMICOLON;
        }

      {WHITE_SPACE_AND_CRLF} { return TokenType.WHITE_SPACE; }
}

<ATTRIBUTE_VALUE> {
    {UNICODE_RANGE} { yybegin(ATTRIBUTE_VALUE_END);return WXSSTypes.UNICODE_RANGE; }
          {HASH} { yybegin(ATTRIBUTE_VALUE_END);return WXSSTypes.HASH;}
          {NUMBER}|{NUMBER_WITH_UNIT} { yypushback(yylength());yybegin(ATTRIBUTE_VALUE_NUMBER); }
          "'" {
              yybegin(ATTRIBUTE_VALUE_STRING_START_SQ);
              return WXSSTypes.STRING_START_SQ;
          }
          "\"" {
              yybegin(ATTRIBUTE_VALUE_STRING_START_DQ);
              return WXSSTypes.STRING_START_DQ;
          }
          {FUNCTION_NAME}{WHITE_SPACE_AND_CRLF}?"(" {
                    yypushback(yylength());
                    yybegin(ATTRIBUTE_VALUE_FUNCTION);
                }
           {ATTRIBUTE_VALUE_LITERAL} {
                yybegin(ATTRIBUTE_VALUE_END);
              return WXSSTypes.ATTRIBUTE_VALUE_LITERAL;
          }
}

<ATTRIBUTE_VALUE_END,ATTRIBUTE_VALUE_NUMBER> {
      ";" {
          yybegin(STYLE_SELCTION);
          return WXSSTypes.SEMICOLON;
      }
      "," {
          yybegin(ATTRIBUTE_VALUE_STRAT);
          return WXSSTypes.COMMA;
      }
     "}" {
            yybegin(YYINITIAL);
          return WXSSTypes.RIGHT_BRACKET;
     }
     {WHITE_SPACE_AND_CRLF} { yybegin(ATTRIBUTE_VALUE_STRAT); return TokenType.WHITE_SPACE; }
}

// 属性值中的数字

<ATTRIBUTE_VALUE_NUMBER> {
    {NUMBER} {
        return WXSSTypes.NUMBER;
    }
    {NUMBER_UNIT} {
          return WXSSTypes.NUMBER_UNIT;
    }
}

// 属性值中的字符串

<ATTRIBUTE_VALUE_STRING_START_DQ> {
    "\"" {
        yybegin(ATTRIBUTE_VALUE_END);
        return WXSSTypes.STRING_END_DQ;
    }
    [^\n\"]+ {
        return WXSSTypes.STRING_CONTENT;
    }
}

<ATTRIBUTE_VALUE_STRING_START_SQ> {
    "'" {
        yybegin(ATTRIBUTE_VALUE_END);
        return WXSSTypes.STRING_END_SQ;
    }
    [^\n\']+ {
        return WXSSTypes.STRING_CONTENT;
    }
}

// 属性值中的方法调用
<ATTRIBUTE_VALUE_FUNCTION> {
    {FUNCTION_NAME} {
        return WXSSTypes.FUNCTION_NAME;
    }
    "(" {
        yybegin(ATTRIBUTE_VALUE_FUNCTION_ARGS);
        return WXSSTypes.LEFT_PARENTHESES;
    }
}

<ATTRIBUTE_VALUE_FUNCTION_ARGS>{
    "," {
          return WXSSTypes.COMMA;
      }
      {WHITE_SPACE_AND_CRLF} {
          return TokenType.WHITE_SPACE;
      }
    {IDENTIFIER} {
        return WXSSTypes.ATTRIBUTE_VALUE_LITERAL;
    }
    {NUMBER}|{NUMBER_WITH_UNIT} {
        yypushback(yylength());
        yybegin(ATTRIBUTE_VALUE_FUNCTION_ARG_NUMBER);
    }
      {HASH} {
          return WXSSTypes.HASH;
      }
     ")" {
          yybegin(ATTRIBUTE_VALUE_END);
          return WXSSTypes.RIGHT_PARENTHESES;
      }
}

// 方法中的数字
<ATTRIBUTE_VALUE_FUNCTION_ARG_NUMBER>{
        {NUMBER} {
            return WXSSTypes.NUMBER;
        }
        {WHITE_SPACE_AND_CRLF} {
                yybegin(ATTRIBUTE_VALUE_FUNCTION_ARGS);
                return TokenType.WHITE_SPACE;
        }
        {NUMBER_UNIT} {
              return WXSSTypes.NUMBER_UNIT;
        }
        "," {
          yybegin(ATTRIBUTE_VALUE_FUNCTION_ARGS);
            return WXSSTypes.COMMA;
        }
        ")" {
            yybegin(ATTRIBUTE_VALUE_END);
            return WXSSTypes.RIGHT_PARENTHESES;
        }
}

// 注释，记录进入注释之前的状态
// 再注释结束之后释放
{COMMENT_START} {
    this.saveBeforeCommentState();
    yybegin(COMMENT);
    return WXSSTypes.COMMENT;
}

<COMMENT> {
    {COMMENT_END} {
        yybegin(this.beforeCommentState);
        return WXSSTypes.COMMENT;
    }
    {WHITE_SPACE_AND_CRLF} {
          return TokenType.WHITE_SPACE;
      }
    [^] {
        return WXSSTypes.COMMENT;
    }
}
// @font-face

<YYINITIAL> "@font-face" {
          yybegin(STYLE_SELCTION);
    return WXSSTypes.FONT_FACE_KEYWORD;
}

<STRING_START_SQ> {
  "'" { yybegin(this.beforeStringState);return WXSSTypes.STRING_END_SQ; }
   ([^\n\"]|"'")+ { return WXSSTypes.STRING_CONTENT; }
}
<STRING_START_DQ> {
  "\"" { yybegin(this.beforeStringState);return WXSSTypes.STRING_END_DQ; }
  ([^\n"\""]|"\\\"")+ { return WXSSTypes.STRING_CONTENT; }
}

"}" {
  return WXSSTypes.RIGHT_BRACKET;
}

"{" {
    return WXSSTypes.LEFT_BRACKET;
}

"(" { return WXSSTypes.LEFT_PARENTHESES; }
")" { return WXSSTypes.RIGHT_PARENTHESES; }

"\"" { this.saveBeforeStringState();yybegin(STRING_START_DQ);return WXSSTypes.STRING_START_DQ; }

"'" { this.saveBeforeStringState();yybegin(STRING_START_SQ);return WXSSTypes.STRING_START_SQ; }

{WHITE_SPACE_AND_CRLF}                                     { yybegin(YYINITIAL); return TokenType.WHITE_SPACE; }



[^] { return TokenType.BAD_CHARACTER; }