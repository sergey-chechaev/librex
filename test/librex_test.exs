defmodule LibrexTest do
  use ExUnit.Case

  @docx_file Path.join(__DIR__, "fixtures/docx.docx")
  @pptx_file Path.join(__DIR__, "fixtures/pptx.pptx")
  @non_existent_file Path.join(__DIR__, "fixtures/non.existent")

  test ".convert docx to pdf" do
    pdf_file = random_path <> ".pdf"
    refute File.exists? pdf_file
    { :ok, out_file } = Librex.convert(@docx_file, pdf_file)
    assert pdf_file == out_file
    assert is_pdf? pdf_file
  end

  test ".convert pptx to pdf" do
    pdf_file = random_path <> ".pdf"
    refute File.exists? pdf_file
    { :ok, out_file } = Librex.convert(@pptx_file, pdf_file)
    assert pdf_file == out_file
    assert is_pdf? pdf_file
  end

  test ".convert docx to odt" do
    odt_file = random_path <> ".odt"
    refute File.exists? odt_file
    { :ok, out_file } = Librex.convert(@docx_file, odt_file)
    assert odt_file == out_file
    assert is_odt? odt_file
  end

  test ".convert must return error when file to convert does not exist" do
    { :error, reason } = Librex.convert(@non_existent_file, "/tmp/output.pdf")
    assert reason == :enoent
  end

  test ".convert! must return output file path" do
    pdf_file = random_path <> ".pdf"
    out_file = Librex.convert!(@docx_file, pdf_file)
    assert pdf_file == out_file
  end

  test ".convert! must raise error when file to convert does not exist" do
    msg = "could not read #{@non_existent_file}: no such file or directory"
    assert_raise File.Error, msg, fn ->
      Librex.convert!(@non_existent_file, "/tmp/output.pdf")
    end
  end

  test "convert must return error when LibreOffice executable can't be found" do
    cmd = "sofice" # misspelled
    msg = "LibreOffice (#{cmd}) executable could not be found."
    {:error, reason} = Librex.convert(@docx_file, "/tmp/output.pdf", "sofice")
    assert reason == msg
  end

  test "convert! must raise error when LibreOffice executable can't be found" do
    cmd = "sofice" # misspelled
    msg = "LibreOffice (#{cmd}) executable could not be found."

    assert_raise RuntimeError, msg, fn ->
      Librex.convert!(@docx_file, "/tmp/output.pdf", "sofice")
    end
  end

  test "convert must have the possibility to specify LibreOffice command" do
    pdf_file = random_path <> ".pdf"
    { :ok, out_file } = Librex.convert(@docx_file, pdf_file, System.find_executable("soffice"))
    assert pdf_file == out_file
    assert is_pdf? pdf_file
  end

  test "convert must return error when file to convert is directory" do
    pdf_file = random_path <> ".pdf"
    assert Librex.convert(System.tmp_dir!, pdf_file) == {:error, :eisdir}
  end

  test ".convert! must raise error when file to convert is directory" do
    msg = "could not read #{System.tmp_dir!}: illegal operation on a directory"
    assert_raise File.Error, msg, fn ->
      Librex.convert!(System.tmp_dir!, "/tmp/output.pdf")
    end
  end

  test "convert must return error when output file has wrong extension" do
    { :error, reason } = Librex.convert(@docx_file, "/tmp/output.mp3")
    assert reason == "mp3 is not a supported output format"
  end

  test "convert! must raise error when output file has wrong extension" do
    msg = "mp3 is not a supported output format"
    assert_raise RuntimeError, msg, fn ->
      Librex.convert!(@docx_file, "/tmp/output.mp3")
    end
  end

  defp is_pdf?(file) do
    { :ok, data } = File.read(file)
    String.starts_with? data, "%PDF"
  end

  defp is_odt?(file) do
    { :ok, data } = File.read(file)
    String.contains? data, "application/vnd.oasis.opendocument.text"
  end

  defp random_path do
    System.tmp_dir! <> "/" <> SecureRandom.uuid
  end
end
