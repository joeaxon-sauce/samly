defmodule SamlyIdpDataTest do
  use ExUnit.Case
  require Samly.Esaml
  alias Samly.{Esaml, IdpData, SpData}

  @sp_config1 %{
    id: "sp1",
    entity_id: "urn:test:sp1",
    certfile: "test/data/test.crt",
    keyfile: "test/data/test.pem"
  }

  @idp_config1 %{
    id: "idp1",
    sp_id: "sp1",
    base_url: "http://samly.howto:4003/sso",
    metadata_file: "test/data/idp_metadata.xml"
  }

  setup context do
    sp_data = SpData.load_provider(@sp_config1)
    [sps: %{sp_data.id => sp_data}] |> Enum.into(context)
  end

  test "valid-idp-config-1", %{sps: sps} do
    %IdpData{} = idp_data = IdpData.load_provider(@idp_config1, sps)
    assert idp_data.valid?
  end

  # verify defaults
  test "valid-idp-config-2", %{sps: sps} do
    %IdpData{} = idp_data = IdpData.load_provider(@idp_config1, sps)
    refute idp_data.use_redirect_for_req
    assert idp_data.sign_requests
    assert idp_data.sign_metadata
    assert idp_data.signed_assertion_in_resp
    assert idp_data.signed_envelopes_in_resp
  end

  test "valid-idp-config-3", %{sps: sps} do
    idp_config =
      Map.merge(@idp_config1, %{
        use_redirect_for_req: false,
        sign_requests: true,
        sign_metadata: true,
        signed_assertion_in_resp: true,
        signed_envelopes_in_resp: true
      })

    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    refute idp_data.use_redirect_for_req
    assert idp_data.sign_requests
    assert idp_data.sign_metadata
    assert idp_data.signed_assertion_in_resp
    assert idp_data.signed_envelopes_in_resp
  end

  test "valid-idp-config-4", %{sps: sps} do
    idp_config =
      Map.merge(@idp_config1, %{
        use_redirect_for_req: true,
        sign_requests: false,
        sign_metadata: false,
        signed_assertion_in_resp: false,
        signed_envelopes_in_resp: false
      })

    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.use_redirect_for_req
    refute idp_data.sign_requests
    refute idp_data.sign_metadata
    refute idp_data.signed_assertion_in_resp
    refute idp_data.signed_envelopes_in_resp
  end

  test "valid-idp-config-5", %{sps: sps} do
    idp_config = %{@idp_config1 | base_url: nil}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
    assert idp_data.base_url == nil
  end

  test "valid-idp-config-6", %{sps: sps} do
    idp_config = Map.put(@idp_config1, :pre_session_create_pipeline, MyPipeline)
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
    assert idp_data.pre_session_create_pipeline == MyPipeline
  end

  test "valid-idp-config-7", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/azure_fed_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
  end

  test "valid-idp-config-8", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/onelogin_idp_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
  end

  test "valid-idp-config-9", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/shibboleth_idp_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
  end

  test "valid-idp-config-10", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/simplesaml_idp_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
  end

  test "valid-idp-config-11", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/testshib_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?
  end

  test "url-test-1", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/shibboleth_idp_metadata.xml"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?

    Esaml.esaml_idp_metadata(
      login_location: sso_url,
      logout_location: slo_url
    ) = idp_data.esaml_idp_rec

    assert sso_url |> List.to_string() |> String.ends_with?("/SAML2/POST/SSO")
    assert slo_url |> List.to_string() |> String.ends_with?("/SAML2/POST/SLO")
  end

  test "url-test-2", %{sps: sps} do
    idp_config = %{@idp_config1 | metadata_file: "test/data/shibboleth_idp_metadata.xml"}
    idp_config = Map.put(idp_config, :use_redirect_for_req, true)
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    assert idp_data.valid?

    Esaml.esaml_idp_metadata(
      login_location: sso_url,
      logout_location: slo_url
    ) = idp_data.esaml_idp_rec

    assert sso_url |> List.to_string() |> String.ends_with?("/SAML2/Redirect/SSO")
    assert slo_url |> List.to_string() |> String.ends_with?("/SAML2/Redirect/SLO")
  end

  @tag :skip
  test "invalid-idp-config-1", %{sps: sps} do
    idp_config = %{@idp_config1 | id: ""}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    refute idp_data.valid?
  end

  test "invalid-idp-config-2", %{sps: sps} do
    idp_config = %{@idp_config1 | sp_id: "unknown-sp"}
    %IdpData{} = idp_data = IdpData.load_provider(idp_config, sps)
    refute idp_data.valid?
  end
end
