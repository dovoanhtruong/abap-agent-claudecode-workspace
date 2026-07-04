---
name: abap-generative-ai
description: Help with implementing Generative AI within ABAP Cloud using ISLM (Intelligent Scenario Lifecycle Management) and the ABAP AI SDK. Use when users ask about Generative AI, AI SDK, ISLM, LLM, OpenAI in ABAP, Azure OpenAI, Hub, prompts, completions, embeddings in ABAP. Triggers include "generative ai", "ai sdk", "islm", "llm", "tích hợp ai", "openai abap".
---

# ABAP Generative AI

Guide for integrating Large Language Models (LLMs) and Generative AI into ABAP applications using the **ABAP AI SDK** powered by ISLM (Intelligent Scenario Lifecycle Management).

## Workflow

1. **Verify Prerequisites**:
   - Ensure the system is configured for Generative AI Hub or Azure OpenAI.
   - The appropriate Communication Arrangements are active.
2. **Select the Use Case**:
   - Chat Completion (generating text, answering questions)
   - Embeddings (vector representation for search)
3. **Implement using the ABAP AI SDK**.

## ABAP AI SDK Reference

The core interfaces reside in the `IF_AISA_*` (AI SDK ABAP) packages.

### Chat Completions

Calling an LLM to generate a response based on a user prompt.

```abap
CLASS zcl_demo_ai_chat DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_demo_ai_chat IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    TRY.
        " 1. Create the AI Profile / Destination (Scenario mapped in ISLM)
        DATA(lo_destination) = cl_aisa_destination_factory=>create_by_scenario( 'ZMY_LLM_SCENARIO' ).
        
        " 2. Initialize the AI client for Chat Completion
        DATA(lo_client) = cl_aisa_chat_comp_factory=>create( lo_destination ).
        
        " 3. Build the request payload
        DATA(lo_request) = cl_aisa_chat_comp_request=>create( ).
        
        " Add System Prompt (Context)
        lo_request->add_message(
          role    = if_aisa_chat_comp_msg_role=>system
          content = 'You are a helpful ABAP development assistant.'
        ).
        
        " Add User Prompt
        lo_request->add_message(
          role    = if_aisa_chat_comp_msg_role=>user
          content = 'Explain the difference between VALUE and REDUCE in ABAP.'
        ).
        
        " 4. Set model parameters (optional)
        lo_request->set_temperature( '0.7' ).
        lo_request->set_max_tokens( 500 ).
        
        " 5. Execute the call
        DATA(lo_response) = lo_client->execute( lo_request ).
        
        " 6. Process response
        DATA(lt_choices) = lo_response->get_choices( ).
        IF lines( lt_choices ) > 0.
          out->write( lt_choices[ 1 ]-message-content ).
        ENDIF.
        
      CATCH cx_aisa_exception INTO DATA(lx_error).
        out->write( |AI Error: { lx_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

### Embeddings

Generating vector embeddings for text, usually for RAG (Retrieval-Augmented Generation) scenarios.

```abap
CLASS zcl_demo_ai_embed DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_demo_ai_embed IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    TRY.
        " 1. Create Destination for Embedding Scenario
        DATA(lo_dest) = cl_aisa_destination_factory=>create_by_scenario( 'ZMY_EMBED_SCENARIO' ).
        
        " 2. Create Embedding Client
        DATA(lo_client) = cl_aisa_embedding_factory=>create( lo_dest ).
        
        " 3. Build Request
        DATA(lo_request) = cl_aisa_embedding_request=>create( ).
        lo_request->add_input( 'This is a sample text to be converted into an embedding vector.' ).
        
        " 4. Execute
        DATA(lo_response) = lo_client->execute( lo_request ).
        
        " 5. Get Vector
        DATA(lt_data) = lo_response->get_data( ).
        IF lines( lt_data ) > 0.
          DATA(lt_vector) = lt_data[ 1 ]-embedding.
          out->write( |Embedding generated with { lines( lt_vector ) } dimensions.| ).
        ENDIF.

      CATCH cx_aisa_exception INTO DATA(lx_error).
        out->write( |Error: { lx_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

## Best Practices
- Avoid hardcoding model names (e.g., `gpt-4`). Always use ISLM configuration (Scenarios) to map models dynamically.
- Handle `CX_AISA_EXCEPTION` carefully, as network/quota issues are common with LLMs.
- Consider token limits when building context for RAG.

## References
- SAP ABAP Cheat Sheets — Generative AI (30_Generative_AI)
- SAP Help Portal: ABAP AI SDK
