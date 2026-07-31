#include "totvs.ch"

/*/{Protheus.doc} CAWFCTChk
Verifica se a inclusao do contrato gerou pendencia de alcada (SCR,
CR_TIPO = "CT") e, em caso positivo, posiciona CN9 e dispara o e-mail de
aprovacao (CAWFCT01). Chamada pelo ponto de entrada CNTA300, no evento
MODELCOMMITNTTS.
@type function
@author Delson Junior Antunes
@since 06/07/2026
@param oModel, object, modelo de dados do contrato (CNTA300) recebido em ParamIXB[1]
/*/
User Function CAWFCTChk(oModel)

	Local cFilCtr   := oModel:GetValue("CN9_FILIAL")
	Local cNumCtr   := oModel:GetValue("CN9_NUMERO")
	Local cRevisa   := oModel:GetValue("CN9_REVISA")
	Local lPendente := .F.
	Local aAreaCN9  := CN9->(GetArea())
	Local aAreaSCR  := SCR->(GetArea())

	If Empty(cNumCtr)
		Return
	EndIf

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	If SCR->(dbSeek(xFilial("SCR") + "CT" + cNumCtr))
		If SCR->CR_STATUS == "02"
			lPendente := .T.
		EndIf
	EndIf

	If lPendente
		CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
		If CN9->(dbSeek(cFilCtr + cNumCtr + cRevisa))
			U_CAWFCT01()
		EndIf
	EndIf

	CN9->(RestArea(aAreaCN9))
	SCR->(RestArea(aAreaSCR))

Return
