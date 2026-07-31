#include "protheus.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
#include "topconn.ch"
#Include 'ApWebEx.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³M110STTS  ºAutor  ³Luciano Siqueira    º Data ³  16/03/2024 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³PE apos gravacao da solicitacao de compras                  º±±
±±º          ³para ativacao de WF do controle de alcadas                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE                                                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function M110STTS()

	Local aArea := GetArea()
	Local lAprov:= .F.

	If Inclui .Or. Altera .Or. lCopia

		cQuery := " SELECT * "
		cQuery += "	FROM "+RetSqlName("SC1")+" SC1 (NOLOCK)"
		cQuery += "	WHERE "
		cQuery += "		C1_FILIAL = '"+xFilial("SC1")+"' AND "
		cQuery += "		C1_NUM = '"+SC1->C1_NUM+"' AND "
		cQuery += "		C1_APROV = 'B' AND "
		cQuery += "		SC1.D_E_L_E_T_='' "

		If Select("TSQC1") > 0
			dbSelectArea("TSQC1")
			TSQC1->(dbCloseArea())
		EndIf

		dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), "TSQC1", .F., .F.)

		dbSelectArea("TSQC1")
		TSQC1->(dbGotop())
		If TSQC1->(!EOF())
			lAprov:= .T.		
		Endif

		If Select("TSQC1") > 0
			dbSelectArea("TSQC1")
			TSQC1->(dbCloseArea())
		EndIf

		If lAprov
			u_EDWFPC03()
		Endif
	
	Endif

	RestArea(aArea)

Return

