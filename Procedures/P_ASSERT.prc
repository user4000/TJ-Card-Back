   Create Or Replace Procedure CARD_BACK.P_ASSERT (S_GOT In Varchar2, S_EXPECTED In Varchar2, B_EQUAL BOOLEAN) Is
   S_M VARCHAR2(4000);
   V_GOT  VARCHAR2(4000);
   V_EXPECTED VARCHAR2(4000);
   Begin
   
      S_M := NULL;
      V_GOT := TRIM(S_GOT); 
      V_EXPECTED := TRIM(S_EXPECTED);
   
      If (B_EQUAL) AND (V_GOT != V_EXPECTED) Then
         S_M := 'Error! Expected <<' || S_EXPECTED || '>> got <<' || S_GOT || '>>';
      End If;
      
      If (NOT B_EQUAL) AND (V_GOT = V_EXPECTED) Then
         S_M := 'Error!  <<VALUE>> must not be equal <<' || S_GOT || '>>';
      End If;
      
      IF S_M IS NOT NULL THEN
      Raise_Application_Error(-20001, S_M);
      END IF;
      
   End;