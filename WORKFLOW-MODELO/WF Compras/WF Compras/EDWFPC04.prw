#include "protheus.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDWFPC04  ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina de retorno do workflow de aprovação de compras	  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE  		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

user function EDWFPC04(oProcess)

	Local cFilPed   := oProcess:oHtml:RetByName('C7_FILIAL')
	Local cNum 	    := oProcess:oHtml:RetByName('C7_NUM')
	Local nRecno 	:= oProcess:oHtml:RetByName('RECNO')
	Local lAprov 	:= right(Alltrim(Upper(oProcess:oHtml:RetByName('aprovacao'))),1) == "S"
	Local lAllApv   := .T.

	SC1->(dbSetOrder(1))
	if SC1->(dbSeek(xFilial("SC1") + AVKEY(cNum,"C1_NUM")))
		SCR->(dbGoTo(nRecno))
		//Verifica se o registro posicionado está pendente de aprovação
		if SCR->CR_STATUS <> "02"
			return
		endif

		if lAprov
			lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SCR->CR_GRUPO,,,,,oProcess:oHtml:RetByName('MOTIVO')}, date(),4)
		else
			lLiberou := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,,SCR->CR_APROV,,SCR->CR_GRUPO,,,,dDataBase,oProcess:oHtml:RetByName('MOTIVO')}, date(), 7)
			SCR->(reclock("SCR", .F.))
			SCR->CR_OBS := alltrim(oProcess:oHtml:RetByName('MOTIVO'))
			SCR->(msunlock())
		endif
	endif

	cTipo := AVKEY("SC","CR_TIPO")

	// Executa ponto de entrada para verificar se há mais níveis de aprovação
	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	if SCR->(dbSeek(xFilial("SCR") + cTipo + AVKEY(cNum,"CR_NUM")))
		while !SCR->(eof()) .and.SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == AVKEY(cFilPed,"CR_FILIAL") + AVKEY(cTipo,"CR_TIPO") + AVKEY(cNum,"CR_NUM")//alltrim(SCR->CR_FILIAL) + alltrim(SCR->CR_NUM) == cFilPed + cNum
			if SCR->CR_STATUS == "02"
				lAllApv := .F.
				SC1->(dbSetOrder(1))
				if SC1->(dbSeek(xFilial("SC1") + AVKEY(cNum,"C1_NUM")))
					u_EDWFPC03()
					exit
				endif
			elseif SCR->CR_STATUS == "06"
				EDNotif(.F., cNum)
				lAllApv := .F.
				while !SC1->(eof()) .and. SC1->C1_FILIAL == AVKEY(cFilPed,"C1_FILIAL") .and. SC1->C1_NUM == AVKEY(cNum,"C1_NUM")
					SC1->(recLock("SC1", .F.))
					SC1->C1_APROV := "R"
					SC1->(msUnlock())
					SC1->(dbSkip())
				end
				exit
			endif
			SCR->(dbSkip())
		end
		if lAllApv
			if SC1->(dbSeek(xFilial("SC1") + AVKEY(cNum,"C1_NUM")))
				EDNotif(.T., cNum)
				while !SC1->(eof()) .and. SC1->C1_FILIAL == AVKEY(cFilPed,"C1_FILIAL") .and. SC1->C1_NUM == AVKEY(cNum,"C1_NUM")
					SC1->(recLock("SC1", .F.))
					SC1->C1_APROV := "L"
					SC1->(msUnlock())
					SC1->(dbSkip())
				end
			endif
		endif
	endif

	oProcess:Finish()
	oProcess:Free()

return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  | EDNotif   ºAutor  ³ Luciano Siqueira  º Data ³  19/03/24   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Função de notificação de aprovação/rejeição do workflow	  º±±
±±º          ³                                  						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ EDEBE 		                                              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

static function EDNotif(lStatus, cReg)

	Local oNotifica
	//Local cUser 	:= ""
	Local cBody		:= ""

	SC1->(dbSetOrder(1))
	SC1->(dbSeek(xFilial("SC1") + cReg))

	//Função que da o Start no Workflow
	oNotifica := TWFProcess():New("WFNOTIF", "E-mail de Notificação de Solicitacao de Compras")
	//Função que busca o Modelo do HTML
	oNotifica:NewTask("000004", "\WORKFLOW\modelos_workflow\WFNOTIFICA.HTM")
	//Subject do Email
	oNotifica:cSubject := "Solicitacao de Compras Nº " + SC1->C1_NUM + " - " +  iif(lStatus,"APROVADA", "REJEITADA")

	cBody := "<b>Sr(a). " + usrFullName(SC1->C1_USER) + "</b><br><br>"
	cBody += "Notificamos a " + iif(lStatus,"aprovação", "rejeição") + " da Solicitacao de Compras nº <b>" + SC1->C1_NUM + "</b>"
	if len(alltrim(SCR->CR_OBS)) > 0
		cBody += "<br>Motivo: " + alltrim(SCR->CR_OBS) + "<br><br>"
	else
		cBody += "<br><br>"
	endif

	cBody += "Atenciosamente, " + "<br>"
	cBody += "Workflow Protheus | Servico de Mensagens" + "<br>"

	oNotifica:oHtml:ValByName("BODY", cBody)

	oNotifica:cTo := usrRetMail(SC1->C1_USER)

	//oNotifica:cTo := "vleonardo@deltadecisao.com.br"
	
	oNotifica:Start()
	oNotifica:Free()

return
