defmodule Shun.Preset.AWS do
  @moduledoc """
  Provides an AWS-related rule which forbids access to the EC2 Instance Metadata endpoint.

  Rules within this Preset are based on:

  - [Instance Metadata and User Data][1]

  [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
  """

  @behaviour Shun.Preset

  @impl Shun.Preset
  def rules do
    [
      Shun.Rule.reject(%URI{host: "169.254.169.254"}),
      Shun.Rule.reject("169.254.169.254")
    ]
  end
end
